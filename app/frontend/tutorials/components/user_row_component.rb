class UserRowComponent < ViewComponent::Base
  def initialize(user:, assignment:, tutorial:)
    super()
    @user = user
    @assignment = assignment
    @tutorial = tutorial
    @participation ||= @user.assessment_participation_in_assignment(@assignment)
  end

  # Determines if grading is enabled for the current assignment
  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && @assignment.assessable?
  end

  # Determines if grading is allowed for the current assignment
  def allow_grading?
    !@assignment.active?
  end

  def extract_task_points_participation(assessment_task)
    submission_points = @participation.graded_tasks_points
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

  def row_id
    "user-row-#{@user.id}"
  end

  def task_points_participation_input(assignment_task, allow_grading)
    tag.input(
      type: "number",
      autocomplete: "off",
      name: "task_points[#{assignment_task.id}]",
      value: extract_task_points_participation(assignment_task),
      step: 0.5,
      min: 0,
      max: assignment_task.max_points,
      data: {
        submission_row_target: "input",
        task_id: assignment_task.id,
        action: "change->submission-row#markDirtyUser input->submission-row#markDirtyUser"
      },
      class: "form-control",
      disabled: !allow_grading
    )
  end

  def task_points_participation_cell(assignment_task, allow_grading)
    tag.td(class: "sticky-col task-col") do
      task_points_participation_input(assignment_task, allow_grading)
    end
  end

  def save_row_button(allow_grading)
    class_name = "btn btn-sm btn-success d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"

    tag.button(type: "button",
               class: class_name,
               data: { bs_toggle: "tooltip", action: "click->submission-row#saveRow" },
               title: helpers.t("buttons.save"),
               disabled: !allow_grading) do
      tag.i(class: "bi bi-save")
    end
  end

  def refresh_row_button(allow_grading)
    class_name = "btn btn-sm btn-outline-secondary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"

    tag.button(type: "button",
               class: class_name,
               data: { bs_toggle: "tooltip", action: "click->submission-row#refreshRow" },
               title: helpers.t("buttons.refresh"),
               disabled: !allow_grading) do
      tag.i(class: "bi bi-arrow-clockwise")
    end
  end
end
