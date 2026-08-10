module Assessment
  # Makes an assessable carry a final grade — a talk, an exam — as opposed to
  # only points. The grade lands on the participation, not here.
  module Gradable
    extend ActiveSupport::Concern
    include ::Assessment::Assessable

    def ensure_gradebook!
      requires_points = assessment&.requires_points
      ensure_assessment!(
        requires_points: requires_points || false,
        requires_submission: false
      )
    end

    # A grade is either a number on the German scale or a word like "passed",
    # and which one it is follows from the value itself.
    def set_grade!(user:, value:, grader: nil)
      gradebook = assessment || raise("No gradebook; call ensure_gradebook! first")
      # Not `create_or_find_by!`: that only rescues the database's unique
      # violation, and the model's own uniqueness validation raises first.
      participation = gradebook.assessment_participations
                               .find_or_create_by!(user_id: user.id)

      participation.update!(
        **grade_attributes_for(value),
        grader_id: grader&.id,
        graded_at: Time.current,
        status: :reviewed
      )
    end

    private

      def grade_attributes_for(value)
        return { grade_numeric: value.to_f } if numeric_grade?(value)

        { grade_text: value.to_s }
      end

      def numeric_grade?(value)
        value.is_a?(Numeric) || value.to_s.match?(/\A\d+(\.\d+)?\z/)
      end
  end
end
