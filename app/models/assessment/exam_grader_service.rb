module Assessment
  # Handles participation lookup/creation for exam grading and pointing.
  class ExamGraderService
    class ExamGraderError < StandardError; end

    class << self
      def set_grade(participation, grade, grader, comment = nil)
        raise_if_errors!(
          validate_participation_present(participation)
        )
        assessment = participation.assessment
        raise_if_errors!(
          validate_assessment_belongs_to_exam(assessment),
          authorize_exam_grade!(participation.assessment&.assessable, grader)
        )

        grade_info = GradeEntryService.build_grade_info(grade_numeric: grade)
        GradeEntryService.set_grade(participation, grade_info, grader, comment)
      end

      def score_tasks_by_participation!(participation, points_by_task_id, scorer)
        raise_if_errors!(validate_participation_present(participation))

        exam = participation.assessment&.assessable

        raise_if_errors!(
          validate_participation_has_exam(participation, exam),
          validate_exam_grading_open(exam),
          authorize_exam_point!(participation.assessment&.assessable, scorer)
        )

        PointEntryService.enter_points(participation, points_by_task_id, scorer, nil)
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

      # Given [assessment, user] pairs, loads all existing participations
      # and creates only the missing ones.
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

        def authorize_exam_grade!(exam, user)
          return if exam.nil? || user.can_enter_grades_in?(exam.lecture)

          I18n.t("assessment.errors.user_cannot_grade")
        end

        def authorize_exam_point!(exam, user)
          return if exam.nil? || user.can_enter_points_in?(exam.lecture)

          I18n.t("assessment.errors.user_cannot_grade")
        end

        def validate_exam_grading_open(exam)
          return if exam.nil? || exam.grading_open?

          I18n.t("assessment.task_points.cannot_score_not_grading_open_exam")
        end

        def validate_participation_has_exam(participation, exam)
          return if exam.present?

          I18n.t("assessment.task_points.participation_id_has_no_exam",
                 participation_id: participation.id)
        end

        def validate_participation_present(participation)
          return if participation.present?

          I18n.t("assessment.errors.no_participation")
        end

        def raise_if_errors!(*errors)
          errors = errors.flatten.compact
          raise(ExamGraderError, errors.join("; ")) if errors.any?
        end
    end
  end
end
