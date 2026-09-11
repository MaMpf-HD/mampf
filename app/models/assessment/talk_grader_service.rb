module Assessment
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

      def find_participation(assessment, user)
        return if assessment.nil? || user.nil?

        Participation.find_by(
          assessment_id: assessment.id,
          user_id: user.id
        )
      end

      def create_participation(assessment, user)
        Participation.create!(assessment_id: assessment.id, user_id: user.id, status: :pending)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        Participation.find_by!(assessment_id: assessment.id, user_id: user.id)
      end

      # Given a list of [assessment, user]
      # pairs, loads all existing participations in one query and creates only
      # the missing ones.
      # Returns a hash keyed by [assessment_id, user_id].
      def init_participations(pairs)
        pairs = pairs.reject { |assessment, user| assessment.nil? || user.nil? }
        return {} if pairs.empty?

        assessment_ids = pairs.map { |assessment, _user| assessment.id }.uniq
        user_ids = pairs.map { |_assessment, user| user.id }.uniq

        index = Participation
                .where(assessment_id: assessment_ids, user_id: user_ids)
                .index_by { |p| [p.assessment_id, p.user_id] }

        pairs.each_with_object(index) do |(assessment, user), memo|
          key = [assessment.id, user.id]
          next if memo.key?(key)

          memo[key] = create_participation(assessment, user)
        end
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
