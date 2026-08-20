# Renders a single participation row in the pointing table
class ParticipationRowComponent < ViewComponent::Base
  class MissingUserError < StandardError; end

  def initialize(participation:, assignment:, tutorial: nil, mode: nil)
    super()
    @participation = participation
    @assignment = assignment
    @mode = mode || "tutor"
    @user ||= @participation&.user
    if @mode == "tutor"
      @tutorial = tutorial
      @lecture = @tutorial.lecture
    elsif @mode == "teacher"
      @tutorial = tutorial
      @lecture = assignment.lecture
    end

    return unless @user.nil?

    raise(MissingUserError,
          I18n.t("assessment.grading_tutorial.no_user_for_config",
                 participation_id: @participation.id, assignment_id: @assignment.id))
  end

  # Determines if grading is enabled for the current assignment
  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && @assignment.assessable?
  end

  # Determines if grading is allowed for the current assignment
  def allow_grading?
    @assignment.grading_open?
  end

  def extract_task_points_participation(assessment_task)
    graded_task_points.find do |sp|
      sp.task_id == assessment_task.id
    end&.points
  end

  def graded_task_points
    @graded_task_points ||= @participation.graded_tasks_points
  end

  def tasks
    @assignment.assessment.persisted_tasks || []
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
    "participation-row-#{@participation.id}"
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
        action: "change->submission-row#onPointParticipationChanged input->submission-row#onPointParticipationChanged" # rubocop:disable Layout/LineLength
      },
      class: "form-control",
      disabled: !allow_grading || !grading_enabled? || !can_grade?
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
               data: { bs_toggle: "tooltip",
                       submission_row_target: "save",
                       action: "click->submission-row#saveRow" },
               title: helpers.t("buttons.save"),
               disabled: !allow_grading || !grading_enabled? || !can_grade?) do
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
               disabled: !allow_grading || !grading_enabled? || !can_grade?) do
      tag.i(class: "bi bi-arrow-clockwise")
    end
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

      participation_user_ids.each_with_object({}) do |user_id, result|
        current_tutorial = tutorial_memberships.find { |m| m.user_id == user_id }&.tutorial
        old_tutorial = participations.find { |p| p.user_id == user_id }&.tutorial
        next unless current_tutorial&.id != old_tutorial&.id

        old_title = old_tutorial&.title
        new_title = current_tutorial&.title

        result[user_id] = {
          old_tutorial_title: old_title || t("assessment.grading_tutorial.no_tutorial"),
          new_tutorial_title: new_title || t("assessment.grading_tutorial.no_tutorial")
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
