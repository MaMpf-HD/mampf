# Renders a single submission row in the pointing table
class SubmissionRowComponent < ViewComponent::Base
  def initialize(submission:, assignment:, tutorial: nil, mode: nil)
    super()
    @submission = submission
    @assignment = assignment
    @tutorial = tutorial
    @lecture = @tutorial.lecture
    @mode = mode || "tutor"
  end

  # Feature guard: grading is only possible if the feature flag is enabled
  # and the assignment supports assessment
  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && @assignment.assessable?
  end

  # Business rule: grading is only allowed once the assignment is no longer active
  # and the submission is valid for pointing (i.e. not late or rejected)
  def allow_grading?
    @submission.valid_for_pointing? && @assignment.grading_open?
  end

  def tasks
    @assignment.assessment.persisted_tasks || []
  end

  def late?
    @submission.too_late?
  end

  def row_id
    "submission-row-#{@submission.id}"
  end

  def extract_task_points(assessment_task)
    graded_task_points.find do |sp|
      sp.task_id == assessment_task.id
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
        action: "change->submission-row#onPointSubmissionChanged input->submission-row#onPointSubmissionChanged" # rubocop:disable Layout/LineLength
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
                       submission_row_target: "save",
                       action: "click->submission-row#saveRow" },
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

  def late_submission_info(submission, tutorial)
    text = t("submission.late")
    return text unless submission.accepted.nil? && helpers.current_user.in?(tutorial.tutors)

    "#{text} (#{t("tutorial.late_submission_decision")})"
  end

  def can_grade?
    user = helpers.current_user
    user.admin? || user.can_grade_in_scope?(@tutorial)
  end

  def users_movement_map
    return {} unless @assignment.past_deadline?

    helpers.users_movement_map_cache.fetch(@assignment.id) do
      tutorial_memberships = @lecture.tutorials
                                     .includes(:tutorial_memberships)
                                     .flat_map(&:tutorial_memberships)
      participations = @assignment.assessment&.assessment_participations&.to_a
      return {} if participations.nil?

      participation_user_ids = participations.map(&:user_id)
      member_user_ids = tutorial_memberships.map(&:user_id)

      ids = (participation_user_ids | member_user_ids) - (participation_user_ids & member_user_ids)

      ids.each_with_object({}) do |user_id, result|
        current_tutorial = tutorial_memberships.find { |m| m.user_id == user_id }&.tutorial
        old_tutorial = participations.find { |p| p.user_id == user_id }&.tutorial
        next unless current_tutorial&.id != old_tutorial&.id

        result[user_id] = {
          old_tutorial_id: old_tutorial&.id,
          new_tutorial_id: current_tutorial&.id,
          old_tutorial_title: old_tutorial&.title ||
                              t("assessment.grading_tutorial.no_tutorial"),
          new_tutorial_title: current_tutorial&.title ||
                              t("assessment.grading_tutorial.no_tutorial")
        }
      end
    end
  end

  def movement_info_for_user(user)
    movement = users_movement_map[user.id]
    return nil unless movement

    old_tutorial_title = movement[:old_tutorial_title]
    new_tutorial_title = movement[:new_tutorial_title]
    t("assessment.grading_tutorial.user_moved_tutorial",
      old_tutorial: old_tutorial_title || t("assessment.grading_tutorial.no_tutorial"),
      new_tutorial: new_tutorial_title || t("assessment.grading_tutorial.no_tutorial"))
  end
end
