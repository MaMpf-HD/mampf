module Assessment
  class GradeEntryService
    VALID_GRADES_NUMERIC = [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0].freeze

    def self.set_grade(participation, grade_info, grader, comment = nil)
      assessment = participation.assessment

      unless assessment&.assessable.is_a?(Gradable)
        raise(GradeEntryError,
              I18n.t("assessment.errors.not_gradable", assessment_id: assessment&.id))
      end

      grade_info = validate_grade_info(grade_info)
      status = calculate_status(participation, grade_info)

      participation.update!(
        grade_text: grade_info[:grade_text],
        grade_numeric: grade_info[:grade_numeric],
        grader_id: grader.id,
        graded_at: Time.current,
        status: status,
        note: comment || participation.note
      )
    end

    # Returns :reviewed if a grade is provided, :pending if no grade is provided,
    # and retains the current status if the participation is exempt or absent.
    def self.calculate_status(participation, new_grade_info)
      if participation.exempt? || participation.absent?
        participation.status
      elsif new_grade_info[:grade_numeric].present? || new_grade_info[:grade_text].present?
        :reviewed
      else
        :pending
      end
    end

    def self.build_grade_info(grade_numeric: nil, grade_text: nil)
      {
        grade_numeric: grade_numeric,
        grade_text: grade_text
      }
    end

    def self.validate_grade_info(input_grade)
      numeric_grade = input_grade[:grade_numeric]
      numeric_grade = numeric_grade.to_s.strip
      numeric_grade_f = numeric_grade.to_f if numeric_grade.match?(/\A\d+(\.\d+)?\z/)
      if numeric_grade_f&.in?(VALID_GRADES_NUMERIC)
        {
          grade_numeric: numeric_grade_f,
          grade_text: input_grade[:grade_text]
        }
      elsif numeric_grade.blank?
        {
          grade_numeric: nil,
          grade_text: input_grade[:grade_text]
        }
      else
        raise(GradeEntryError,
              I18n.t("assessment.errors.invalid_grade", grade: numeric_grade))
      end
    end

    class GradeEntryError < StandardError; end
  end
end
