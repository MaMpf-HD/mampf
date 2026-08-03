module Assessment
  # One student's row in a gradebook: whether they turned up, what they scored
  # and what they were given for it.
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

    private

      # Nothing may be marked before the assessable says grading is open. Leaving
      # `pending` counts as marking even when no grade is written with it, which
      # is why the status is checked separately from the attribute list.
      def grading_lifecycle_must_be_open
        return if assessment&.grading_open?

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
