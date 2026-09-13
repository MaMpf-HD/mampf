module Assessment
  class TalkGraderService
    class TalkGraderError < StandardError; end

    class << self
      # Who may grade is the controller's question; here only whether this
      # participation is a talk's.
      def set_grade(participation, grade, grader, comment = nil)
        raise_if_errors!(validate_participation_present(participation))
        raise_if_errors!(validate_assessment_belongs_to_talk(participation.assessment))

        grade_info = GradeEntryService.build_grade_info(grade_numeric: grade)
        GradeEntryService.set_grade(participation, grade_info, grader, comment)
      end

      # Two tabs opening the seminar at once race for the same row; the unique
      # index decides, and the loser reads what the winner wrote.
      def create_participation(assessment, user)
        Participation.create!(assessment_id: assessment.id, user_id: user.id, status: :pending)
      rescue ActiveRecord::RecordNotUnique
        Participation.find_by!(assessment_id: assessment.id, user_id: user.id)
      end

      # Drawing the table creates the rows it lacks - a deliberate exception
      # to reads that write nothing. Speakers reach a talk through the roster
      # in bulk, past any callback, and a row without an id could not be
      # graded through its route; the create is idempotent on the unique index.
      def init_participations(pairs)
        pairs = pairs.reject { |assessment, user| assessment.nil? || user.nil? }
        return {} if pairs.empty?

        assessment_ids = pairs.map { |assessment, _user| assessment.id }.uniq
        user_ids = pairs.map { |_assessment, user| user.id }.uniq

        index = Participation
                .includes(:user, :grader, assessment: :assessable)
                .where(assessment_id: assessment_ids, user_id: user_ids)
                .index_by { |p| [p.assessment_id, p.user_id] }

        pairs.each_with_object(index) do |(assessment, user), memo|
          key = [assessment.id, user.id]
          next if memo.key?(key)

          memo[key] = create_participation(assessment, user)
        end
      end

      private

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
