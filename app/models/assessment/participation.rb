module Assessment
  class Participation < ApplicationRecord
    belongs_to :assessment, class_name: "Assessment::Assessment",
                            inverse_of: :assessment_participations
    belongs_to :user
    belongs_to :tutorial, optional: true
    belongs_to :grader, class_name: "User", optional: true, inverse_of: false

    has_many :task_points, dependent: :destroy,
                           class_name: "Assessment::TaskPoint",
                           foreign_key: :assessment_participation_id,
                           inverse_of: :assessment_participation

    enum :status, {
      pending: 0,
      reviewed: 1,
      absent: 2,
      exempt: 3
    }

    scope :submitted, -> { where.not(submitted_at: nil) }

    after_commit :recompute_performance_record,
                 if: :should_recompute_performance_record?

    validates :user_id, uniqueness: { scope: :assessment_id }
    validates :grade_numeric,
              inclusion: {
                in: [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0],
                allow_nil: true
              }
    validate :assessment_must_be_gradable, if: -> { grade_numeric.present? }

    def self.tutorial_for(user, lecture)
      TutorialMembership.joins(:tutorial)
                        .where(tutorials: { lecture_id: lecture.id },
                               user_id: user.id)
                        .pick(:tutorial_id)
    end

    def display_status
      if pending? && submitted_at.nil?
        :not_submitted
      elsif pending?
        :pending_grading
      else
        status.to_sym
      end
    end

    private

      def should_recompute_performance_record?
        achievement_grade_text_changed? ||
          saved_change_to_status? ||
          saved_change_to_submitted_at?
      end

      def achievement_grade_text_changed?
        saved_change_to_grade_text? &&
          assessment&.assessable_type == "Achievement"
      end

      def recompute_performance_record
        lecture = assessment&.lecture
        return unless lecture && Flipper.enabled?(:student_performance)

        StudentPerformance::ComputationService
          .new(lecture: lecture)
          .compute_and_upsert_record_for(user)
      end

      def assessment_must_be_gradable
        return unless assessment&.assessable
        return if assessment.assessable.is_a?(::Assessment::Gradable)

        errors.add(:grade_numeric, :not_gradable)
      end
  end
end
