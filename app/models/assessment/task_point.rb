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
    validate :grading_lifecycle_must_be_open

    after_commit :refresh_participation_points_total,
                 on: [:create, :update, :destroy],
                 if: :refresh_participation_points_total?

    private

      def grading_lifecycle_must_be_open
        return if assessment_participation&.assessment&.grading_open?

        errors.add(:base, :early_grading_not_allowed)
      end

      def refresh_participation_points_total
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
      end

      def refresh_participation_points_total?
        destroyed? || saved_change_to_points?
      end

      def ensure_task_and_participation_match_assessment
        return unless task && assessment_participation
        return if task.assessment_id == assessment_participation.assessment_id

        errors.add(:base, :assessment_mismatch)
      end
  end
end
