class Achievement < ApplicationRecord
  include Assessment::Assessable

  belongs_to :lecture

  has_many :rule_achievements,
           class_name: "StudentPerformance::RuleAchievement",
           dependent: :restrict_with_error

  enum :value_type, { boolean: 0, numeric: 1, percentage: 2 }

  validates :title, :value_type, presence: true
  validates :threshold,
            numericality: { greater_than: 0 },
            if: :numeric?
  validates :threshold,
            numericality: { greater_than_or_equal_to: 0,
                            less_than_or_equal_to: 100 },
            if: :percentage?
  validates :threshold, absence: true, if: :boolean?

  after_create :setup_assessment,
               if: -> { Flipper.enabled?(:assessment_grading) }

  def student_met_threshold?(user)
    return false unless assessment

    participation = assessment.assessment_participations
                              .find_by(user: user)
    return false if participation.nil? || participation.grade_text.blank?

    case value_type
    when "boolean"
      participation.grade_text == "pass"
    when "numeric"
      participation.grade_text.to_i >= threshold
    when "percentage"
      participation.grade_text.to_f >= threshold
    end
  end

  private

    def setup_assessment
      ensure_assessment!(requires_points: false, requires_submission: false)
      seed_participations!
    end

    def seed_participations!
      return unless assessment

      user_ids = lecture.members.pluck(:id)
      assessment.seed_participations_from!(user_ids: user_ids)
    end
end
