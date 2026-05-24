class SubmissionRowComponent < ViewComponent::Base
  def initialize(submission:, assignment:, tutorial:)
    super()
    @submission = submission
    @assignment = assignment
    @tutorial = tutorial
  end

  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && @assignment.assessable?
  end

  def tasks
    @assignment.assessment.tasks
  end

  def late?
    @submission.too_late?
  end

  def row_id
    "submission-row-#{@submission.id}"
  end

  def extract_task_points(assessment_task)
    submission_points = @submission.graded_tasks_points
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
end