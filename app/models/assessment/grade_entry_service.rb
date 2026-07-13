module Assessment
  class GradeEntryService
    # TODO: add validation permission lecture
    # only support text grade for now
    def self.set_grade(participation, grade, grader, comment = nil)
      assessment = participation.assessment

      unless assessment.gradable? # concern check
        raise(GradeEntryError,
              I18n.t("assessment.grades.not_gradable", assessment_id: assessment.id))
      end

      validate_grade_text!(grade)

      participation.update!(
        grade_text: grade,
        grader_id: grader.id,
        graded_at: Time.current,
        status: :reviewed,
        note: comment || participation.note
      )
    end

    def self.validate_grade_text!(grade)
      return if VALID_TALK_GRADES.include?(grade)

      raise(GradeEntryError,
            I18n.t("assessment.grades.invalid_grade", grade: grade))
    end
  end
end
