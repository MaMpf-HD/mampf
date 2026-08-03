# Something a student has to have done besides collecting points — held a
# blackboard talk, handed in a project. It carries no points of its own; the
# tutor records a value per student, and an eligibility rule can require it.
class Achievement < ApplicationRecord
  include Assessment::Assessable

  # What a tutor records for an achievement that is simply done or not done.
  # Written by the marking view, read here — keep both ends on this constant.
  PASSED = "pass".freeze

  belongs_to :lecture

  enum :value_type, { boolean: 0, numeric: 1, percentage: 2 }

  validates :title, :value_type, presence: true
  validates :title, uniqueness: { scope: :lecture_id }
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

  after_commit :invalidate_performance_records,
               on: [:update, :destroy],
               if: :should_invalidate_performance_records?

  # A German keyboard writes 3,5 and means three and a half. Returns nil for
  # anything that is no number at all, so callers can say so rather than
  # counting it as zero.
  def self.numeric_value(grade_text)
    BigDecimal(grade_text.to_s.strip.tr(",", "."))
  rescue ArgumentError
    nil
  end

  # The one place that decides whether a recorded value clears this
  # achievement. The marking table and the performance computation both ask
  # here, so the two cannot answer differently.
  def met_by?(grade_text)
    value = grade_text.to_s.strip
    return false if value.blank?
    return value == PASSED if boolean?
    return false if threshold.nil?

    number = self.class.numeric_value(value)
    return refuse_unreadable(value) if number.nil?

    number >= threshold
  end

  private

    # Said out loud: a wrong "not met" here costs a student their exam
    # admission, and there is nothing else to notice it by.
    def refuse_unreadable(value)
      Rails.logger.warn do
        "Achievement #{id}: cannot read #{value.inspect} as a number"
      end
      false
    end

    def threshold_or_type_changed?
      saved_change_to_threshold? || saved_change_to_value_type?
    end

    def should_invalidate_performance_records?
      destroyed? || threshold_or_type_changed?
    end

    def invalidate_performance_records
      return unless Flipper.enabled?(:assessment_grading)

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
