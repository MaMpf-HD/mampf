module Assessment
  class SubmissionGraderService
    # Enters points for one task for all team members
    def self.score_task!(submission,
                         task,
                         team_points, # points
                         grader)
      assessment = submission&.assignment&.assessment
      return if assessment.nil?

      users = submission.users
      users.each do |user|
        participation = init_participation(assessment, user)
        PointEntryService.enter_points(
          participation,
          { task.id => team_points },
          grader
        )
      end
    end

    # Enters points for all tasks for all team members
    def self.score_tasks!(submission,
                          points_by_task_id, # Hash of task_id => points, points potentially nil and string
                          scorer)
      assessment = submission&.assignment&.assessment
      return if assessment.nil?

      users = submission.users
      users.each do |user|
        participation = init_participation(assessment, user)
        PointEntryService.enter_points(
          participation,
          points_by_task_id,
          scorer
        )
      end
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
