# Renders a single participation row in the pointing table
class ParticipationRowComponent < ViewComponent::Base
  class MissingUserError < StandardError; end

  def initialize(participation:, assessment:, grading_scope:,
                 save_url:, refresh_url:)
    super()
    @participation = participation
    @assessment = assessment
    @assessable = assessment.assessable
    @lecture = @assessable.lecture
    @save_url = save_url
    @refresh_url = refresh_url
    @grading_scope = grading_scope
    @user ||= @participation&.user
    @tutorial = (@grading_scope if @grading_scope.is_a?(Tutorial))

    @config = Assessment::DisplayConfigResolver.resolve(
      assessable: @assessable, grading_scope: @grading_scope
    )
    @mode = @config.mode

    return unless @user.nil?

    raise(MissingUserError,
          I18n.t("assessment.grading_tutorial.no_user_for_config",
                 participation_id: @participation&.id))
  end

  def tasks?
    @config.body_mode == :tasks
  end

  def grade?
    @config.body_mode == :single_grade
  end

  def single_grade?
    @config.body_mode == :single_grade
  end

  def show_tutorial_col?
    @config.left_columns.include?(:tutorial)
  end

  def show_correction_col?
    @config.right_columns.include?(:correction)
  end

  delegate :stimulus_controller, to: :@config

  def grading_enabled?
    @assessable.assessable?
  end

  def allow_grading?
    @assessable.grading_open?
  end

  def extract_task_points_participation(task)
    graded_task_points.find do |sp|
      sp.task_id == task.id
    end&.points
  end

  def graded_task_points
    @graded_task_points ||= @participation.graded_tasks_points
  end

  def tasks
    @assessable.assessment.persisted_tasks || []
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

  def task_points_participation_input(task, allow_grading)
    tag.input(
      type: "number",
      autocomplete: "off",
      name: "task_points[#{task.id}]",
      value: extract_task_points_participation(task),
      step: 0.5,
      min: 0,
      data: {
        participation_row_target: "input",
        task_id: task.id,
        below_min_message: t("assessment.grading_tutorial.point_below_minimum", min: 0),
        action: "change->participation-row#onPointParticipationChanged input->participation-row#onPointParticipationChanged" # rubocop:disable Layout/LineLength
      },
      class: "form-control",
      disabled: !allow_grading || !grading_enabled? || !can_grade?
    )
  end

  def task_points_participation_cell(task, allow_grading)
    tag.td(class: "sticky-col task-col") do
      task_points_participation_input(task, allow_grading)
    end
  end

  # ---- single_grade mode helpers (ported from GradeTalkRowComponent) ----

  def status_value
    @participation&.status || :pending
  end

  def grade_numeric
    @participation&.grade_numeric
  end

  def grade_display
    return "—" if grade_numeric.blank?

    I18n.t("assessment.grades.#{grade_numeric}", default: grade_numeric)
  end

  def grade_options
    Assessment::GradeEntryService::VALID_GRADES_NUMERIC.map do |g|
      [I18n.t("assessment.grades.#{g}", default: g), g]
    end
  end

  def grader_display
    @participation&.grader&.tutorial_name
  end

  def graded_at_relative
    return nil unless @participation&.graded_at

    helpers.time_ago_in_words(@participation.graded_at)
  end

  def graded_at_full
    return nil unless @participation&.graded_at

    I18n.l(@participation.graded_at, format: :short)
  end

  # ---- shared buttons ----

  def save_row_button(allow_grading)
    class_name = "btn btn-sm btn-success d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"
    tag.button(type: "button",
               class: class_name,
               data: { bs_toggle: "tooltip",
                       "participation-row_target": "save",
                       action: "click->participation-row#saveRow" },
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
               data: { bs_toggle: "tooltip", action: "click->participation-row#refreshRow" },
               title: helpers.t("buttons.refresh"),
               disabled: !allow_grading || !grading_enabled? || !can_grade?) do
      tag.i(class: "bi bi-arrow-clockwise")
    end
  end

  def can_grade?
    user = helpers.current_user
    user.admin? || user.can_grade_in_scope?(@grading_scope)
  rescue User::IncompatibleTypeError
    false
  end

  def users_movement_map
    helpers.users_movement_map_cache[@assessable.id] ||=
      helpers.calculate_user_movement_map_assignment(@assessable, @lecture)
  end

  def movement_info_for_user(user)
    helpers.movement_info_for_user_assignment(user, users_movement_map)
  end
end
