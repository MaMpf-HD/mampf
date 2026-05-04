module Assessment
  class TaskPoint < ApplicationRecord
    belongs_to :assessment_participation,
               class_name: "Assessment::Participation",
               inverse_of: :task_points
    belongs_to :task, class_name: "Assessment::Task",
                      inverse_of: :task_points
    belongs_to :grader, class_name: "User", optional: true, inverse_of: false
    belongs_to :submission, optional: true, inverse_of: false

    validates :points, numericality: { greater_than_or_equal_to: 0 },
                       allow_nil: true
    validate :ensure_task_and_participation_match_assessment

    after_commit :sync_participation_points_total,
                 on: [:create, :update, :destroy],
                 if: :refresh_participation_points_total?

    private

      def sync_participation_points_total
        return unless assessment_participation_id

        sum = self.class
                  .where(
                    assessment_participation_id: assessment_participation_id
                  )
                  .sum(:points)

        participation = ::Assessment::Participation.find_by(
          id: assessment_participation_id
        )
        participation&.update!(points_total: sum)
        recompute_performance_record(participation)
      end

      def refresh_participation_points_total?
        destroyed? || saved_change_to_points?
      end

      def recompute_performance_record(participation)
        return unless participation&.user

        lecture = participation.assessment&.lecture
        return unless lecture && Flipper.enabled?(:student_performance)

        StudentPerformance::ComputationService
          .new(lecture: lecture)
          .compute_and_upsert_record_for(participation.user)
      end

      def ensure_task_and_participation_match_assessment
        return unless task && assessment_participation
        return if task.assessment_id == assessment_participation.assessment_id

        errors.add(:base, :assessment_mismatch)
      end
  end
end
