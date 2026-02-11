class Cohort < ApplicationRecord
  include Registration::Registerable
  include Rosters::Rosterable

  belongs_to :context, polymorphic: true

  has_many :cohort_memberships, dependent: :destroy
  has_many :users, through: :cohort_memberships
  has_many :members, through: :cohort_memberships, source: :user

  enum :purpose, {
    general: 0,
    enrollment: 1,
    planning: 2
  }

  attr_readonly :propagate_to_lecture

  validates :title, presence: true
  validates :purpose, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validate :validate_purpose_propagate_compatibility

  def roster_entries
    cohort_memberships
  end

  def lecture
    context if context.is_a?(Lecture)
  end

  def registration_title
    title
  end

  private

    def validate_purpose_propagate_compatibility
      case purpose
      when "enrollment"
        errors.add(:purpose, :enrollment_must_propagate) unless propagate_to_lecture?
      when "planning"
        errors.add(:purpose, :planning_cannot_propagate) if propagate_to_lecture?
      end
    end
end
