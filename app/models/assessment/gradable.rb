module Assessment
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

    def set_grade!(user:, value:, grader: nil)
      a = assessment || raise("No gradebook; call ensure_gradebook! first")
      part = a.assessment_participations.find_or_create_by!(user_id: user.id)

      grade_attrs = if value.is_a?(Numeric) || value.to_s.match?(/^\d+(\.\d+)?$/)
        { grade_numeric: value.to_f }
      else
        { grade_text: value.to_s }
      end

      part.update!(
        **grade_attrs,
        grader_id: grader&.id,
        graded_at: Time.current,
        status: :graded
      )
    end
  end
end
