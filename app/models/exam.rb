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

  after_create :setup_assessment, if: -> { Flipper.enabled?(:assessment_grading) }
  after_create :create_registration_campaign,
               if: -> { !skip_campaigns && Flipper.enabled?(:registration_campaigns) }

  def roster_entries
    exam_rosters
  end

  def roster_association_name
    :exam_rosters
  end

  def registration_campaign
    Registration::Item.find_by(registerable: self)&.registration_campaign
  end

  def registration_title
    return title unless date

    "#{title} (#{I18n.l(date, format: :short)})"
  end

  private

    def setup_assessment
      ensure_pointbook!(requires_submission: false)
    end

    def create_registration_campaign
      deadline = registration_deadline.presence || date || 1.month.from_now
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
end
