# Represents a student's participation in an assessment. It tracks the student's
# submission status, grade, and other relevant information.
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

    validates :user_id, uniqueness: { scope: :assessment_id }
    validate :grading_lifecycle_must_be_open
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

    def recompute_points_total!
      update!(points_total: task_points.sum(:points))
    end

    # absent and exempt -> no change
    # pending -> reviewed if all tasks scored, otherwise remains pending
    # reviewed -> pending if any task points are changed to nil, otherwise remains reviewed
    def update_status_if_all_scored!
      return if absent? || exempt?

      if pending? && !task_points.exists?(points: nil)
        update!(status: :reviewed)
        return
      end

      return unless reviewed? && task_points.exists?(points: nil)

      update!(status: :pending)
    end

    def graded_tasks_points
      TaskPoint.where(assessment_participation: self).distinct(:task_id)
    end

    private

      def grading_lifecycle_must_be_open
        # Allow new/pending changes to pass, or modifications when grading is explicitly open.
        return if assessment&.grading_open?

        # An array intersection checks if any of the critical grading attributes were modified.
        # "status_changed?(from: 'pending')" is evaluated manually, since `changes.keys` only
        # checks if it changed at all.
        changed_grading_attributes =
          changes.keys.intersect?(["grade_numeric", "grade_text",
                                   "points_total", "grader_id", "graded_at"])
        status_changed_from_pending = status_changed?(from: "pending")

        return unless changed_grading_attributes || status_changed_from_pending

        errors.add(:base, :early_grading_not_allowed)
      end

      def assessment_must_be_gradable
        return unless assessment&.assessable
        return if assessment.assessable.is_a?(::Assessment::Gradable)

        errors.add(:grade_numeric, :not_gradable)
      end
  end
end
