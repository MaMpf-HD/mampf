class SubmissionRowComponent < ViewComponent::Base
  def initialize(submission:, assignment:, tutorial:)
    super()
    @submission = submission
    @assignment = assignment
    @tutorial = tutorial
  end

  # Determines if grading is enabled for the current assignment
  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && @assignment.assessable?
  end

  # Determines if grading is allowed for the current assignment
  def allow_grading?
    !@assignment.active?
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
    end&.points
  end

  def badge_status_participation_color(status)
    {
      pending: "warning",
      reviewed: "success",
      exempt: "info",
      absent: "info"
    }[status&.to_sym]
  end

  def badge_status_participation_class(status)
    "badge rounded-pill bg-#{badge_status_participation_color(status)}"
  end

  def task_points_input(assignment_task, allow_grading)
    tag.input(
      type: "number",
      autocomplete: "off",
      name: "task_points[#{assignment_task.id}]",
      value: extract_task_points(assignment_task),
      step: 0.5,
      min: 0,
      max: assignment_task.max_points,
      data: {
        submission_row_target: "input",
        task_id: assignment_task.id,
        action: "change->submission-row#markDirty input->submission-row#markDirty"
      },
      class: "form-control",
      disabled: !allow_grading
    )
  end

  def save_row_button(allow_grading)
    class_name = "btn btn-sm btn-success d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"

    tag.button(type: "button",
               class: class_name,
               data: { bs_toggle: "tooltip" },
               title: helpers.t("buttons.save"),
               data_action: "click->submission-row#saveRow",
               disabled: !allow_grading) do
      tag.i(class: "bi bi-save")
    end
  end

  def refresh_row_button(allow_grading)
    class_name = "btn btn-sm btn-outline-secondary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"

    tag.button(type: "button",
               class: class_name,
               data: { bs_toggle: "tooltip" },
               title: helpers.t("buttons.refresh"),
               data_action: "click->submission-row#refreshRow",
               disabled: !allow_grading) do
      tag.i(class: "bi bi-arrow-clockwise")
    end
  end
end
