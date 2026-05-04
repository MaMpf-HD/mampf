module Assessment
  class Task < ApplicationRecord
    belongs_to :assessment, class_name: "Assessment::Assessment",
                            inverse_of: :tasks
    has_many :task_points, dependent: :destroy,
                           class_name: "Assessment::TaskPoint", inverse_of: :task

    validates :max_points, numericality: { greater_than_or_equal_to: 0 }
    validate :assessment_requires_points

    before_destroy :check_no_points_entered, prepend: true
    before_destroy :check_deadline_not_passed, prepend: true

    after_commit :recompute_all_performance_records,
                 on: [:create, :destroy]
    after_commit :recompute_all_performance_records,
                 on: :update,
                 if: :saved_change_to_max_points?

    acts_as_list scope: :assessment

    def points_entered?
      task_points.where.not(points: nil).exists?
    end

    def deadline_passed?
      return false unless assessment&.assessable.is_a?(Assignment)

      assessment.assessable.past_deadline?
    end

    private

      def assessment_requires_points
        return if assessment&.requires_points

        errors.add(:base, :requires_points_true)
      end

      def check_no_points_entered
        throw(:abort) if points_entered?
      end

      def check_deadline_not_passed
        return unless assessment&.assessable.is_a?(Assignment)

        throw(:abort) if assessment.assessable.past_deadline?
      end

      def recompute_all_performance_records
        lecture = assessment&.lecture
        return unless lecture && Flipper.enabled?(:student_performance)
        return if StudentPerformance::Record.where(lecture_id: lecture.id).none?

        StudentPerformance::ComputationService
          .new(lecture: lecture)
          .compute_and_upsert_all_records!
      end
  end
end
