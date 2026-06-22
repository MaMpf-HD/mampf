module Assessment
  # delegates to PointEntryService for actual point recording
  # triggers Participation.recompute_points_total! after point entry (via PointEntryService)
  # validates that the task belongs to the submission's assessment (via PointEntryService)
  # Only allows scoring if the assignment is inactive (after deadline)

  class SubmissionGraderService
    class SubmissionGraderError < StandardError; end

    # Routes a bulk entry to the correct scoring method based on target type.
    def self.score_tasks_by_types!(entry, scorer, tutorial:, assignment:)
      case entry["target"]
      when "submission"
        submission = tutorial.submissions.find(entry["id"])

        raise_if_errors!([
                           validate_submission_matches_assignment(submission, assignment)
                         ])

        score_tasks_by_submission!(submission, entry["task_points"], scorer)
      when "participation"
        participation = assignment.assessment
                                  .assessment_participations
                                  .find(entry["id"])

        raise_if_errors!([validate_participation_matches_tutorial(participation, tutorial)])

        score_tasks_by_participation!(participation, entry["task_points"], scorer)
      else
        raise(SubmissionGraderError, "Unknown target type #{entry["target"].inspect}")
      end
    end

    # Enters points of all tasks for all team members of a submission
    # points_by_task_id, Hash of task_id => points, points potentially nil and string
    def self.score_tasks_by_submission!(submission, points_by_task_id, scorer)
      raise_if_errors!([validate_submission_present(submission)])

      assignment = submission.assignment
      assessment = assignment&.assessment

      raise_if_errors!([
                         validate_submission_has_assignment(submission, assignment),
                         validate_assignment_has_assessment(assignment, assessment)
                       ])
      raise_if_errors!([
                         validate_assessment_requires_points(assessment),
                         validate_assignment_inactive(assignment)
                       ])

      handle_score_tasks_by_submission(assessment, submission, points_by_task_id, scorer)
    end

    def self.score_tasks_by_participation!(participation, points_by_task_id, scorer)
      raise_if_errors!([validate_participation_present(participation)])

      assignment = participation.assessment&.assessable

      raise_if_errors!([
                         validate_participation_has_assignment(participation, assignment),
                         validate_assignment_inactive(assignment)
                       ])

      handle_score_tasks_by_participation(participation, points_by_task_id, scorer)
    end

    def self.init_participation(assessment, user, tutorial)
      if tutorial.nil? || assessment.nil? || user.nil?
        raise(SubmissionGraderError, "Assessment, user, and tutorial must be present")
      end

      participation = Participation.find_or_initialize_by(
        assessment_id: assessment.id,
        user_id: user.id
      )
      participation.save! if participation.new_record?
      participation.update!(tutorial_id: tutorial.id) if participation.tutorial_id.nil?
      participation
    end

    # methods call to PointEntryService
    def self.handle_score_tasks_by_participation(participation,
                                                 points_by_task_id,
                                                 scorer)
      PointEntryService.enter_points(
        participation,
        points_by_task_id,
        scorer,
        nil
      )
    end

    def self.handle_score_tasks_by_submission(assessment, submission, points_by_task_id, scorer)
      users = submission.users
      users.each do |user|
        participation = init_participation(assessment, user, submission.tutorial)
        PointEntryService.enter_points(
          participation,
          points_by_task_id,
          scorer,
          submission
        )
      end
    end

    # validation methods: each returns nil (valid) or an error string (invalid) ---

    def self.validate_submission_matches_assignment(submission, assignment)
      return if submission.assignment_id == assignment.id

      I18n.t("assessment.task_points.submission_assignment_mismatch",
             submission_id: submission.id,
             assignment_id: assignment.id)
    end

    def self.validate_participation_matches_tutorial(participation, tutorial)
      return if participation.tutorial_id.nil? || participation.tutorial_id == tutorial.id

      I18n.t("assessment.task_points.participation_tutorial_mismatch",
             participation_id: participation.id,
             tutorial_id: tutorial.id)
    end

    def self.validate_submission_has_assignment(submission, assignment)
      return if assignment.present?

      I18n.t("assessment.task_points.submission_has_no_assignment",
             submission_id: submission.id)
    end

    def self.validate_assignment_has_assessment(assignment, assessment)
      return if assessment.present?

      I18n.t("assessment.task_points.assignment_has_no_assessment",
             assignment_id: assignment.id)
    end

    def self.validate_participation_has_assignment(participation, assignment)
      return if assignment.present?

      I18n.t("assessment.task_points.participation_has_no_assignment",
             participation_id: participation.id)
    end

    def self.validate_assignment_inactive(assignment)
      return if assignment.nil? || !assignment.active?

      I18n.t("assessment.task_points.cannot_score_active_assignment")
    end

    def self.validate_assessment_requires_points(assessment)
      return if assessment.nil? || assessment.requires_points?

      I18n.t("assessment.task_points.not_required_points")
    end

    def self.validate_submission_present(submission)
      return if submission.present?

      I18n.t("assessment.task_points.submission_missing")
    end

    def self.validate_participation_present(participation)
      return if participation.present?

      I18n.t("assessment.task_points.participation_missing")
    end

    #  error-raising helper ---

    def self.raise_if_errors!(errors)
      errors = errors.compact
      raise(SubmissionGraderError, errors.join("; ")) if errors.any?
    end

    private_class_method :raise_if_errors!,
                         :validate_submission_matches_assignment,
                         :validate_participation_matches_tutorial,
                         :validate_submission_has_assignment,
                         :validate_assignment_has_assessment,
                         :validate_participation_has_assignment,
                         :validate_assignment_inactive,
                         :validate_assessment_requires_points,
                         :validate_submission_present,
                         :validate_participation_present,
                         :handle_score_tasks_by_submission,
                         :handle_score_tasks_by_participation
  end
end
