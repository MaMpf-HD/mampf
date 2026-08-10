module Assessment
  # Represents a specific task within an assessment, which can have points assigned to it.
  class Task < ApplicationRecord
    belongs_to :assessment, class_name: "Assessment::Assessment",
                            inverse_of: :tasks
    has_many :task_points, dependent: :destroy,
                           class_name: "Assessment::TaskPoint", inverse_of: :task

    validates :max_points, numericality: { greater_than_or_equal_to: 0 }
    validate :assessment_requires_points

    # Inside the create transaction, so it also runs before the recompute below
    # and that one sees corrected statuses.
    after_create :reopen_reviewed_participations

    before_destroy :check_no_points_entered, prepend: true

    after_commit :recompute_all_performance_records,
                 on: [:create, :update, :destroy],
                 if: lambda {
                   previously_new_record? || destroyed? ||
                     saved_change_to_max_points?
                 }

    acts_as_list scope: :assessment

    def points_entered?
      task_points.where.not(points: nil).exists?
    end

    private

      def assessment_requires_points
        return if assessment&.requires_points

        errors.add(:base, :requires_points_true)
      end

      def check_no_points_entered
        throw(:abort) if points_entered?
      end

      # Nobody has scored the new task yet, so nobody is fully marked any more.
      # One statement rather than one per participation, inside the create
      # transaction — the task and the reopening stand or fall together.
      def reopen_reviewed_participations
        # rubocop:disable Rails/SkipsModelValidations
        assessment.assessment_participations
                  .where(status: :reviewed)
                  .update_all(status: :pending, updated_at: Time.current)
        # rubocop:enable Rails/SkipsModelValidations
      end

      def recompute_all_performance_records
        return unless assessment&.lecture_id
        return unless Flipper.enabled?(:assessment_grading)

        StudentPerformance::ComputationService
          .new(lecture: assessment.lecture)
          .compute_and_upsert_all_records!
      end
  end
end
