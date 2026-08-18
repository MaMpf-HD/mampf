module Assessment
  # Delegates to GradeEntryService for actual grade recording.
  # ensure permission and not require points
  class TalkGraderService
    class TalkGraderError < StandardError; end

    class << self
      def set_grade(participation, grade, grader, comment = nil)
        raise_if_errors!(
          validate_participation_present(participation)
        )
        assessment = participation.assessment
        raise_if_errors!(
          validate_assessment_belongs_to_talk(assessment)
        )
        raise_if_errors!(
          authorize_talk!(participation.assessment&.assessable, grader)
        )

        grade_info = GradeEntryService.build_grade_info(grade_numeric: grade)
        GradeEntryService.set_grade(participation, grade_info, grader, comment)
      end

      def init_participation(assessment, user, talk)
        if assessment.nil? || user.nil? || talk.nil?
          raise(TalkGraderError,
                I18n.t("assessment.talk_grader.init_participation_missing_args"))
        end

        Participation.find_or_initialize_by(
          assessment_id: assessment.id,
          user_id: user.id
        )
      end

      private

        def authorize_talk!(talk, user)
          return if talk.nil? || user.can_grade_in_scope?(talk.lecture)

          I18n.t("assessment.errors.user_cannot_grade")
        end

        def validate_assessment_belongs_to_talk(assessment)
          return if assessment&.assessable.is_a?(Talk)

          I18n.t("assessment.talk_grader.assessment_not_talk")
        end

        def validate_participation_present(participation)
          return if participation.present?

          I18n.t("assessment.errors.no_participation")
        end

        def raise_if_errors!(*errors)
          errors = errors.flatten.compact
          raise(TalkGraderError, errors.join("; ")) if errors.any?
        end
    end
  end
end
