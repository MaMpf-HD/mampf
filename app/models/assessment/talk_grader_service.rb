module Assessment
  # Delegates to GradeEntryService for actual grade recording.
  # ensure permission and not require points
  #
  class TalkGraderService
    class TalkGraderError < StandardError; end

    class << self
      def set_grade(participation, grade, grader, comment = nil)
        raise_if_errors!(
          validate_participation_present(participation),
          validate_participation_has_assessment(participation)
        )

        assessment = participation.assessment

        raise_if_errors!(
          validate_assessment_belongs_to_talk(assessment)
        )

        raise_if_errors!(
          validate_assessment_gradable(assessment),
          authorize_talk!(participation.assessment&.assessable, grader),
          validate_assessment_not_requires_points(assessment)
        )

        grade_info = GradeEntryService.validate_grade_info(grade)

        GradeEntryService.set_grade(participation, grade_info, grader, comment)
      end

      def init_participation(assessment, user, talk)
        if assessment.nil? || user.nil? || talk.nil?
          raise(TalkGraderError,
                I18n.t("assessment.talks.init_participation_missing_args"))
        end

        participation = Participation.find_or_initialize_by(
          assessment_id: assessment.id,
          user_id: user.id
        )
        participation.update!(talk_id: talk.id) if participation.new_record?
        participation
      end

      private

        # ── entry routing helpers ──────────────────────────────────────────

        # Authorizes the scorer against a talk
        def authorize_talk!(talk, user)
          return if talk.nil? || user.can_grade_in_scope?(talk)

          I18n.t("assessment.talks.user_cannot_grade_talk",
                 talk_id: talk.id, user_id: user.id)
        end

        def validate_assessment_belongs_to_talk(assessment)
          return if assessment&.assessable.is_a?(Talk)

          I18n.t("assessment.talks.assessment_not_talk",
                 assessment_id: assessment.id)
        end

        def validate_participation_present(participation)
          return if participation.present?

          I18n.t("assessment.participation_missing")
        end

        def validate_participation_has_assessment(participation)
          return if participation&.assessment.present?

          I18n.t("assessment.participation_has_no_assessment",
                 participation_id: participation.id)
        end

        def validate_assessment_gradable(assessment)
          return if assessment.nil? || !assessment.requires_points?

          I18n.t("assessment.requires_points",
                 assessable_type: assessment.assessable.class.name)
        end

        # ── error raising ───────────────────────────────────────────────────

        def raise_if_errors!(*errors)
          errors = errors.flatten.compact
          raise(TalkGraderError, errors.join("; ")) if errors.any?
        end
    end
  end
end
