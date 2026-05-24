class UserRowComponent < ViewComponent::Base
  def initialize(user:, assignment:, tutorial:)
    super()
    @user = user
    @assignment = assignment
    @tutorial = tutorial
  end

  def participation
    @participation ||= @user.assessment_participation_in_assignment(@assignment)
  end

  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && @assignment.assessable?
  end

  def extract_task_points_participation(assessment_task)
    submission_points = @participation.graded_tasks_points
    submission_points.find do |sp|
      sp.task_id == assessment_task.id
    end&.points || nil
  end

  def badge_status_participation_color(status)
    {
      pending: "warning",
      reviewed: "success",
      exempt: "info",
      absent: "info"
    }[status&.to_sym]
  end

  def row_id
    "user-row-#{@user.id}"
  end
end