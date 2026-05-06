class Exam < ApplicationRecord
  class ParticipantRemovalNotAllowedError < StandardError; end

  include Assessment::Assessable
  include Registration::Registerable
  include Rosters::Rosterable

  belongs_to :lecture
  has_many :all_exam_roster_entries,
           class_name: "ExamRosterEntry",
           dependent: :destroy,
           inverse_of: :exam
  has_many :exam_roster_entries,
           -> { active },
           class_name: "ExamRosterEntry",
           inverse_of: :exam
  has_many :excluded_exam_roster_entries,
           -> { excluded },
           class_name: "ExamRosterEntry",
           inverse_of: :exam
  has_many :users, through: :exam_roster_entries

  attr_accessor :registration_deadline, :reopen_after_deadline_fix

  validates :title, presence: true
  validates :capacity, numericality: { greater_than: 0 }, allow_nil: true
  validate :registration_deadline_before_exam_date
  validate :registration_deadline_in_future

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

  def roster_entries
    exam_roster_entries
  end

  def roster_association_name
    :exam_roster_entries
  end

  def add_user_to_roster!(user, source_campaign = nil)
    roster_entry = all_exam_roster_entries.find_or_initialize_by(user: user)
    roster_entry.source_campaign ||= source_campaign
    roster_entry.excluded_at = nil
    roster_entry.save!
    roster_entry
  end

  def remove_user_from_roster!(user)
    roster_entry = all_exam_roster_entries.find_by(user: user)
    return unless roster_entry

    if registration_campaign&.completed?
      roster_entry.update!(excluded_at: Time.current)
    else
      roster_entry.destroy
    end
  end

  def status_phase
    campaign = registration_campaign

    if campaign && !campaign.completed?
      return :draft if campaign.draft?
      return :registration_open if campaign.open?
      return :registration_closed if campaign.closed? || campaign.processing?
    end

    return :conducted if date && date < Date.current

    :finalized
  end

  STATUS_PHASE_BADGE_CLASSES = {
    draft: "bg-secondary",
    registration_open: "bg-primary",
    registration_closed: "bg-info",
    finalized: "bg-danger",
    conducted: "bg-light text-dark border"
  }.freeze

  private

    def registration_deadline_before_exam_date
      return if registration_deadline.blank? || date.blank?

      parsed = if registration_deadline.is_a?(String)
        Time.zone.parse(registration_deadline)
      else
        registration_deadline
      end
      return if parsed.blank? || parsed < date

      errors.add(:registration_deadline, :must_be_before_exam_date)
    end

    def registration_deadline_in_future
      return if registration_deadline.blank?

      campaign = registration_campaign unless new_record?
      return if campaign && (campaign.closed? || campaign.completed?)

      parsed = if registration_deadline.is_a?(String)
        Time.zone.parse(registration_deadline)
      else
        registration_deadline
      end
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
      campaign = Registration::Campaign.new(
        campaignable: lecture,
        allocation_mode: :first_come_first_served,
        status: :draft,
        registration_deadline: deadline
      )
      campaign.save!(validate: false)
      Registration::Item.create!(
        registration_campaign: campaign,
        registerable: self,
        capacity: capacity
      )
    end

    def destroy_draft_campaign
      campaign = registration_campaign
      return unless campaign&.draft?

      campaign.destroy!
    end
end
