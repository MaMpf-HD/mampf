module Assessment
  # one submission scored → Assessment::TaskPoint created for each team member
  # delegates to PointEntryService for actual point recording
  # triggers Assessment::Participation.recompute_points_total!
  # after point entry (via PointEntryService)
  # validates that the task belongs to the submission's assessment
  # Wraps all operations in a database transaction for atomicity
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
        participation = init_participation(assessment, user)
        PointEntryService.enter_points(
          participation,
          points_by_task_id,
          scorer,
          submission
        )
      end
    end

    # Enters points of all tasks for 1 user
    def self.score_tasks_by_user!(user, assignment,
                                  points_by_task_id,
                                  scorer)
      assessment = assignment&.assessment
      return if assessment.nil?
      return if assignment.active?

      participation = init_participation(assessment, user)
      PointEntryService.enter_points(
        participation,
        points_by_task_id,
        scorer,
        nil
      )
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

    def self.init_participation(assessment, user)
      participation = Participation.find_or_initialize_by(
        assessment_id: assessment.id,
        user_id: user.id
      )
      participation.save! if participation.new_record?
      participation
    end
  end
end
