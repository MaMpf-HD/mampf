class Achievement < ApplicationRecord
  include Assessment::Assessable

  belongs_to :lecture

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

  after_update_commit :invalidate_performance_records,
                      if: :threshold_or_type_changed?
  after_destroy_commit :invalidate_performance_records

  def student_met_threshold?(user)
    return false unless assessment

    participation = assessment.assessment_participations
                              .find_by(user: user)
    return false if participation.nil? || participation.grade_text.blank?

    case value_type
    when "boolean"
      participation.grade_text == "pass"
    when "numeric"
      numeric_value(participation.grade_text) >= threshold
    when "percentage"
      participation.grade_text.to_f >= threshold
    end
  end

  private

    def numeric_value(value)
      BigDecimal(value.to_s)
    rescue ArgumentError
      BigDecimal("0")
    end

    def threshold_or_type_changed?
      saved_change_to_threshold? || saved_change_to_value_type?
    end

    def invalidate_performance_records
      StudentPerformance::ComputationService
        .new(lecture: lecture)
        .compute_and_upsert_all_records!
    end

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
