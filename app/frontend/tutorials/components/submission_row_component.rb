# Renders a single submission row in the pointing table
class SubmissionRowComponent < ViewComponent::Base
  def initialize(submission:, assignment:, grading_scope:)
    super()
    @submission = submission
    @tutorial = @submission.tutorial
    @assessment = assignment&.assessment
    @assignment = assignment
    @grading_scope = grading_scope
    @lecture = @tutorial.lecture
    check_grading_scope
  end

  def check_grading_scope
    case @grading_scope
    when Tutorial
      @mode = "tutor"
    when Lecture
      @mode = "teacher"
    end
  end

  # Feature guard: grading is only possible if the feature flag is enabled
  # and the assignment supports assessment
  def grading_enabled?
    @assessment.present?
  end

  # Business rule: grading is only allowed once the assignment is no longer active
  # and the submission is valid for pointing (i.e. not late or rejected)
  def allow_grading?
    @submission.valid_for_pointing? && @assignment&.grading_open?
  end

  def tasks
    @assessment.persisted_tasks || []
  end

  def late?
    @submission.too_late?
  end

  def row_id
    "submission-row-#{@submission.id}"
  end

  def extract_task_points(task)
    graded_task_points.find do |sp|
      sp.task_id == task.id
    end&.points
  end

  def graded_task_points
    @graded_task_points ||= @submission.graded_tasks_points
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

  def task_points_input(task, allow_grading)
    tag.input(
      type: "number",
      autocomplete: "off",
      name: "task_points[#{task.id}]",
      value: extract_task_points(task),
      step: 0.5,
      min: 0,
      data: {
        participation_row_target: "input",
        task_id: task.id,
        below_min_message: t("assessment.grading_tutorial.point_below_minimum", min: 0),
        action: "change->participation-row#onPointSubmissionChanged input->participation-row#onPointSubmissionChanged" # rubocop:disable Layout/LineLength
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
               data: { bs_toggle: "tooltip",
                       participation_row_target: "save",
                       action: "click->participation-row#saveRow" },
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
               data: { bs_toggle: "tooltip", action: "click->participation-row#refreshRow" },
               title: helpers.t("buttons.refresh"),
               disabled: !allow_grading) do
      tag.i(class: "bi bi-arrow-clockwise")
    end
  end

  def late_submission_info(submission, tutorial)
    text = t("submission.late")
    return text unless submission.accepted.nil? && helpers.current_user.in?(tutorial.tutors)

    "#{text} (#{t("tutorial.late_submission_decision")})"
  end

  def can_grade?
    user = helpers.current_user
    user.admin? || user.can_grade_in_scope?(@grading_scope)
  end

  def users_movement_map
    return {} unless @assignment.past_deadline?

    helpers.users_movement_map_cache[@assignment.id] ||=
      helpers.calculate_user_movement_map_assignment(@assignment, @lecture)
  end

  def movement_info_for_user(user)
    helpers.movement_info_for_user_assignment(user, users_movement_map)
  end
end
