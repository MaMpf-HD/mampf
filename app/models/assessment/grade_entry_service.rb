module Assessment
  class GradeEntryService
    # TODO: add validation permission lecture
    # only support text grade for now

    VALID_GRADES_NUMERIC = [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0].freeze

    def self.set_grade(participation, grade_info, grader, comment = nil)
      assessment = participation.assessment

      unless assessment.gradable? # concern check
        raise(GradeEntryError,
              I18n.t("assessment.grades.not_gradable", assessment_id: assessment.id))
      end

      participation.update!(
        grade_text: grade_info[:grade_text],
        grade_numeric: grade_info[:grade_numeric],
        grader_id: grader.id,
        graded_at: Time.current,
        status: :reviewed,
        note: comment || participation.note
      )
    end

    def self.validate_grade_info(input_grade)
      numeric_grade = input_grade[:grade_numeric]
      numeric_grade = numeric_grade.to_s.strip
      numeric_grade_f = numeric_grade.to_f if numeric_grade.match?(/\A\d+(\.\d+)?\z/)
      if numeric_grade_f&.in?(VALID_GRADES_NUMERIC)
        {
          grade_numeric: numeric_grade_f,
          grade_text: nil
        }
      else
        raise(GradeEntryError,
              I18n.t("assessment.grades.invalid_grade", grade: numeric_grade))
      end
    end

    class GradeEntryError < StandardError; end
  end
end
