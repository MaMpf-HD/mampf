module Assessment
  # one submission scored → Assessment::TaskPoint created for each team member
  # delegates to PointEntryService for actual point recording
  # triggers Assessment::Participation.recompute_points_total!
  # after point entry (via PointEntryService)
  # validates that the task belongs to the submission's assessment
  # Wraps all operations in a database transaction for atomicity
  # Only allows scoring if the assignment is inactive (after deadline)
  class SubmissionGraderService
    # Enters points of all tasks for all team members
    # points_by_task_id, Hash of task_id => points, points potentially nil and string
    def self.score_tasks_by_submission!(submission,
                                        points_by_task_id,
                                        scorer)
      assignment = submission&.assignment
      assessment = assignment&.assessment
      return if assessment.nil?
      return if assignment.active?

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
      return if assignment.active?

      PointEntryService.enter_points(
        participation,
        points_by_task_id,
        scorer,
        nil
      )
    end

    def self.init_participation(assessment, user, tutorial)
      if tutorial.nil? || assessment.nil? || user.nil?
        raise(ArgumentError, "Assessment, user, and tutorial must be present")
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
