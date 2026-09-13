module Assessment
  # Writes manual grades and notes on assessment participations.
  class GradeEntryService
    class GradeEntryError < StandardError; end

    VALID_GRADES_NUMERIC = (GradeScheme::PASSING_GRADES + [5.0]).sort.freeze

    def self.set_grade(participation, grade_info, grader, comment = nil)
      assessment = participation.assessment

      unless assessment&.assessable.is_a?(Gradable)
        raise(GradeEntryError,
              I18n.t("assessment.errors.not_gradable", assessment_id: assessment&.id))
      end

      grade_info = validate_grade_info(grade_info)
      status = calculate_status(participation, grade_info)
      participation.update!(grade_text: grade_info[:grade_text],
                            grade_numeric: grade_info[:grade_numeric],
                            status: status,
                            note: comment || participation.note,
                            **stamp_for(participation, grade_info, grader, status))
    end

    # Record who changed the grade and when; note-only edits must preserve
    # grader_id and graded_at. Clear both when the status returns to pending.
    def self.stamp_for(participation, grade_info, grader, status)
      return { grader_id: nil, graded_at: nil } if status == :pending
      return {} unless grade_changed?(participation, grade_info)

      { grader_id: grader.id, graded_at: Time.current }
    end

    def self.grade_changed?(participation, grade_info)
      participation.grade_numeric != grade_info[:grade_numeric] ||
        participation.grade_text != grade_info[:grade_text]
    end

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
  end
end
