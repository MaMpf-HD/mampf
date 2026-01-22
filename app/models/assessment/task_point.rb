module Assessment
  class TaskPoint < ApplicationRecord
    belongs_to :assessment_participation,
               class_name: "Assessment::Participation",
               inverse_of: :task_points
    belongs_to :task, class_name: "Assessment::Task",
                      inverse_of: :task_points
    belongs_to :grader, class_name: "User", optional: true
    belongs_to :submission, optional: true

    validates :points, numericality: { greater_than_or_equal_to: 0 },
                       allow_nil: true
    validate :ensure_task_and_participation_match_assessment

    private

      def ensure_task_and_participation_match_assessment
        return unless task && assessment_participation
        return if task.assessment_id == assessment_participation.assessment_id

        errors.add(:base, :assessment_mismatch)
      end
  end
end
