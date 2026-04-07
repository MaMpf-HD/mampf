class Exam < ApplicationRecord
  belongs_to :lecture
  has_many :exam_rosters, dependent: :destroy
  has_many :users, through: :exam_rosters

  include Registration::Registerable
  include Rosters::Rosterable
  include Assessment::Pointable
  include Assessment::Gradable

  attr_accessor :registration_deadline

  validates :title, presence: true
  validates :capacity, numericality: { greater_than: 0, allow_nil: true }
  validate :registration_deadline_before_exam_date
  validate :registration_deadline_in_future

  after_create :setup_assessment, if: -> { Flipper.enabled?(:assessment_grading) }
  after_create :create_registration_campaign,
               if: -> { !skip_campaigns && Flipper.enabled?(:registration_campaigns) }
  after_update :update_campaign_deadline,
               if: lambda {
                 registration_deadline.present? && Flipper.enabled?(:registration_campaigns)
               }
  before_destroy :destroy_draft_campaign, prepend: true

  def non_destructible_reason
    return :roster_not_empty unless roster_empty?

    campaign = registration_campaign
    return :in_campaign if campaign && !campaign.draft?

    nil
  end

  def roster_entries
    exam_rosters
  end

  def roster_association_name
    :exam_rosters
  end

  def registration_campaign
    Registration::Item.find_by(registerable: self)&.registration_campaign
  end

  def load_registration_deadline
    self.registration_deadline = registration_campaign&.registration_deadline
  end

  def registration_title
    return title unless date

    "#{title} (#{I18n.l(date, format: :short)})"
  end

  def status_phase
    campaign = registration_campaign

    if campaign && !campaign.completed?
      return :draft if campaign.draft?
      return :registration_open if campaign.open?
      return :registration_closed if campaign.closed? || campaign.processing?
    end

    if date && date < Date.current
      return :graded if assessment&.results_published?
      return :grading if any_grading_started?

      return :conducted
    end

    :finalized
  end

  STATUS_PHASE_BADGE = {
    draft: "secondary",
    registration_open: "primary",
    registration_closed: "info",
    finalized: "success",
    conducted: "dark",
    grading: "warning",
    graded: "success"
  }.freeze

  private

    def setup_assessment
      ensure_pointbook!(requires_submission: false)
    end

    def registration_deadline_before_exam_date
      return if registration_deadline.blank? || date.blank?

      parsed = registration_deadline.is_a?(String) ? Time.zone.parse(registration_deadline) : registration_deadline
      return if parsed.blank? || parsed < date

      errors.add(:registration_deadline, :must_be_before_exam_date)
    end

    def registration_deadline_in_future
      return if registration_deadline.blank?

      campaign = registration_campaign unless new_record?
      return if campaign && (campaign.closed? || campaign.completed?)

      parsed = registration_deadline.is_a?(String) ? Time.zone.parse(registration_deadline) : registration_deadline
      return if parsed.blank? || parsed > Time.current

      errors.add(:registration_deadline, :must_be_in_future)
    end

    def update_campaign_deadline
      campaign = registration_campaign
      return unless campaign && !campaign.completed?

      campaign.update(registration_deadline: registration_deadline)
    end

    def create_registration_campaign
      deadline = registration_deadline.presence || (date && (date - 3.days)) || 1.month.from_now
      campaign = Registration::Campaign.create!(
        campaignable: lecture,
        allocation_mode: :first_come_first_served,
        status: :draft,
        registration_deadline: deadline
      )
      Registration::Item.create!(
        registration_campaign: campaign,
        registerable: self,
        capacity: capacity
      )
    end

    def any_grading_started?
      assessment&.assessment_participations
                &.where(status: :reviewed)&.exists? || false
    end

    def destroy_draft_campaign
      campaign = registration_campaign
      return unless campaign&.draft?

      campaign.destroy!
    end
end
