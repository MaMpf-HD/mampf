module Assessment
  # Delegates to PointEntryService for actual point recording.
  # Triggers Participation.recompute_points_total! after point entry (via PointEntryService).
  # Validates that the task belongs to the submission's assessment (via PointEntryService).
  # Only allows scoring if the assignment is inactive (after deadline).
  class SubmissionGraderService
    class SubmissionGraderError < StandardError; end

    class << self
      # ── public entrypoints ──────────────────────────────────────────────

      # Scores a batch of mixed submission/participation entries in one transaction.
      # Tutorials/lectures are only authorization-checked once per batch (see
      # `authorize_tutorial_or_lecture!` below).
      def score_multi_teams_by_types!(records, scorer)
        validated_tutorial_ids = []

        ActiveRecord::Base.transaction do
          records.each do |entry|
            score_tasks_by_types!(entry, scorer, validated_tutorial_ids)
          end
        end
      end

      # Routes a single bulk entry to the correct scoring method based on target type.
      def score_tasks_by_types!(entry, scorer, validated_tutorial_ids)
        case entry["target"]
        when "submission"
          score_submission_entry!(entry, scorer, validated_tutorial_ids)
        when "participation"
          score_participation_entry!(entry, scorer, validated_tutorial_ids)
        else
          raise(SubmissionGraderError, "Unknown target type #{entry["target"].inspect}")
        end
      end

      # Enters points of all tasks for all team members of a submission.
      # points_by_task_id: Hash of task_id => points (points potentially nil or a string).
      def score_tasks_by_submission!(submission, points_by_task_id, scorer)
        raise_if_errors!(validate_submission_present(submission))

        assignment = submission.assignment
        assessment = assignment&.assessment

        raise_if_errors!(
          validate_submission_has_assignment(submission, assignment),
          validate_assignment_has_assessment(assignment, assessment),
          validate_assessment_requires_points(assessment),
          validate_assignment_inactive(assignment)
        )

        enter_points_for_each_team_member!(assessment, submission, points_by_task_id, scorer)
      end

      def score_tasks_by_participation!(participation, points_by_task_id, scorer)
        raise_if_errors!(validate_participation_present(participation))

        assignment = participation.assessment&.assessable

        raise_if_errors!(
          validate_participation_has_assignment(participation, assignment),
          validate_assignment_inactive(assignment)
        )

        PointEntryService.enter_points(participation, points_by_task_id, scorer, nil)
      end

      def init_participation(assessment, user, tutorial)
        if assessment.nil? || user.nil? || tutorial.nil?
          raise(SubmissionGraderError,
                I18n.t("assessment.task_points.init_participation_missing_args"))
        end

        participation = Participation.find_or_initialize_by(
          assessment_id: assessment.id,
          user_id: user.id
        )
        participation.update!(tutorial_id: tutorial.id) if participation.new_record?
        participation
      end

      private

        # ── entry routing helpers ──────────────────────────────────────────

        def score_submission_entry!(entry, scorer, validated_tutorial_ids)
          submission = Submission.find(entry["id"])

          authorize_tutorial!(submission.tutorial_id, scorer, validated_tutorial_ids)
          score_tasks_by_submission!(submission, entry["task_points"], scorer)
        end

        def score_participation_entry!(entry, scorer, validated_tutorial_ids)
          participation = Participation.find(entry["id"])

          if participation.tutorial_id.present?
            authorize_tutorial!(participation.tutorial_id, scorer, validated_tutorial_ids)
          else
            raise(SubmissionGraderError,
                  I18n.t("assessment.task_points.participation_missing_tutorial",
                         participation_id: participation.id))
          end

          score_tasks_by_participation!(participation, entry["task_points"], scorer)
        end

        # Authorizes the scorer against a tutorial, skipping the check (and the
        # Tutorial.find lookup) if that tutorial was already validated earlier
        # in this batch.
        def authorize_tutorial!(tutorial_id, scorer, validated_tutorial_ids)
          return if tutorial_id.blank? || validated_tutorial_ids.include?(tutorial_id)

          tutorial = Tutorial.find(tutorial_id)
          raise_if_errors!(validate_current_user_can_grade(tutorial, scorer))
          validated_tutorial_ids << tutorial_id
        end

        # ── point entry ─────────────────────────────────────────────────────

        def enter_points_for_each_team_member!(assessment, submission, points_by_task_id, scorer)
          submission.users.each do |user|
            participation = init_participation(assessment, user, submission.tutorial)
            PointEntryService.enter_points(participation, points_by_task_id, scorer, submission)
          end
        end

        # ── validations: each returns nil (valid) or an error string (invalid) ──

        def validate_submission_present(submission)
          return if submission.present?

          I18n.t("assessment.task_points.submission_missing")
        end

        def validate_participation_present(participation)
          return if participation.present?

          I18n.t("assessment.task_points.participation_missing")
        end

        def validate_submission_has_assignment(submission, assignment)
          return if assignment.present?

          I18n.t("assessment.task_points.submission_has_no_assignment",
                 submission_id: submission.id)
        end

        def validate_participation_has_assignment(participation, assignment)
          return if assignment.present?

          I18n.t("assessment.task_points.participation_has_no_assignment",
                 participation_id: participation.id)
        end

        def validate_assignment_has_assessment(assignment, assessment)
          return if assessment.present?

          I18n.t("assessment.task_points.assignment_has_no_assessment",
                 assignment_id: assignment.id)
        end

        def validate_assessment_requires_points(assessment)
          return if assessment.nil? || assessment.requires_points?

          I18n.t("assessment.task_points.not_required_points")
        end

        def validate_assignment_inactive(assignment)
          return if assignment.nil? || !assignment.active?

          I18n.t("assessment.task_points.cannot_score_active_assignment")
        end

        def validate_current_user_can_grade(scope, user)
          return if scope.nil? || user.can_grade_in_scope?(scope)

          I18n.t("assessment.task_points.user_cannot_grade")
        end

        # ── error raising ───────────────────────────────────────────────────

        def raise_if_errors!(*errors)
          errors = errors.flatten.compact
          raise(SubmissionGraderError, errors.join("; ")) if errors.any?
        end
    end
  end
end
