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
      # The state is read under the row's lock: an absence or exemption
      # recorded meanwhile is seen here, not overwritten.
      participation.with_lock do
        refuse_absent_or_exempt!(participation)
        status = calculate_status(grade_info)
        stamp = stamp_for(participation, grade_info, grader)
        # Without a grade the points decide again whether the row is reviewed;
        # a scheme applied later must not skip a fully scored candidate.
        if status == :pending && participation.all_tasks_scored?
          status = :reviewed
          stamp = { grader_id: nil, graded_at: Time.current, grade_scheme_id: nil }
        end
        participation.update!(grade_text: grade_info[:grade_text],
                              grade_numeric: grade_info[:grade_numeric],
                              status: status,
                              note: comment || participation.note,
                              **stamp)
      end
      participation
    end

    def self.refuse_absent_or_exempt!(participation)
      return unless participation.absent? || participation.exempt?

      status = I18n.t("assessment.grading_exam.status_word.#{participation.status}")
      raise(GradeEntryError, I18n.t("assessment.grading_exam.not_gradable", status: status))
    end

    # Record who changed the grade and when; note-only edits must preserve
    # grader_id and graded_at. No grade, no grader - whatever the status. A
    # grade changed by hand is no longer the scheme's to re-apply.
    def self.stamp_for(participation, grade_info, grader)
      if grade_info.values.none?(&:present?)
        return { grader_id: nil, graded_at: nil, grade_scheme_id: nil }
      end
      return {} unless grade_changed?(participation, grade_info)

      { grader_id: grader.id, graded_at: Time.current, grade_scheme_id: nil }
    end

    def self.grade_changed?(participation, grade_info)
      participation.grade_numeric != grade_info[:grade_numeric] ||
        participation.grade_text != grade_info[:grade_text]
    end

    def self.calculate_status(new_grade_info)
      if new_grade_info[:grade_numeric].present? || new_grade_info[:grade_text].present?
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
