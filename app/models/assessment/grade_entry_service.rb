module Assessment
  class GradeEntryService
    # Sets participation.grade with validation
    # Validates grade format (letter grade, pass/fail, numeric, etc.)
    # Tracks audit information (graded_by_id, graded_at) (via set_grade! in Gradable)
    def self.set_grade(participation, grade, grader)
      assessment = participation.assessment

      # check requires_grade
      unless assessment.requires_grade?
        raise(ArgumentError,
              "Assessment #{assessment.id} does not accept grades")
      end

      # validate grade format
      # TODO

      assessment.ensure_gradebook!

      ApplicationRecord.transaction do
        participation.set_grade!(
          user: participation.user,
          value: grade,
          grader: grader
        )
      end
    end

    # TODO
    def validate_grade_format(standards, grade)
    end
  end
end
