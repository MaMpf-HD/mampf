module Assessment
  # one submission scored → Assessment::TaskPoint created for each team member
  # delegates to PointEntryService for actual point recording
  # triggers Assessment::Participation.recompute_points_total!
  # after point entry (via PointEntryService)
  # validates that the task belongs to the submission's assessment
  # Wraps all operations in a database transaction for atomicity
  # Only allows scoring if the assignment is inactive (after deadline)
  class SubmissionGraderService
    class SubmissionGraderError < StandardError; end

    # Routes a bulk entry to the correct scoring method based on target type.
    def self.score_tasks_by_types!(entry, scorer)
      case entry["target"]
      when "submission"
        submission = Submission.find(entry["id"])
        score_tasks_by_submission!(submission, entry["task_points"], scorer)
      when "participation"
        participation = Participation.find(entry["id"])
        score_tasks_by_participation!(participation, entry["task_points"], scorer)
      end
    end

    # Enters points of all tasks for all team members of a submission
    # points_by_task_id, Hash of task_id => points, points potentially nil and string
    def self.score_tasks_by_submission!(submission,
                                        points_by_task_id,
                                        scorer)
      assignment = submission&.assignment
      assessment = assignment&.assessment
      if assessment.nil?
        raise(SubmissionGraderError,
              I18n.t("assessment.task_points.assessment_not_found"))
      end

      if assignment.active?
        raise(SubmissionGraderError,
              I18n.t("assessment.task_points.cannot_score_active_assignment"))
      end

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

    # Enters points of all tasks for a specific participation
    def self.score_tasks_by_participation!(participation,
                                           points_by_task_id,
                                           scorer)
      assignment = participation&.assessment&.assessable
      return if assignment.nil?

      if assignment.active?
        raise(SubmissionGraderError,
              I18n.t("assessment.task_points.cannot_score_active_assignment"))
      end

      PointEntryService.enter_points(
        participation,
        points_by_task_id,
        scorer,
        nil
      )
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
  end
end
