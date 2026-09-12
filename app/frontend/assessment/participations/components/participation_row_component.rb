# One row of the pointing table for somebody without a hand-in file: a sheet
# taken on paper, one never handed in, an excused or an absent one. Before
# the backfill worker has been round the participation may not exist yet;
# the row is drawn from an unsaved one and offers what makes it real.
class ParticipationRowComponent < ViewComponent::Base
  class MissingUserError < StandardError; end

  def initialize(participation:, assessment:, grading_scope:, group_id: nil,
                 table_option: :pointing)
    super()
    @participation = participation
    @assessment = assessment
    @assessable = assessment.assessable
    @lecture = @assessable.lecture
    @grading_scope = grading_scope
    @tutorial = (@grading_scope if @grading_scope.is_a?(Tutorial))
    @group_id = group_id
    @table_option = table_option
    @config = Assessment::DisplayConfigResolver.resolve(
      assessable: @assessable, grading_scope: @grading_scope
    )

    @user ||= @participation&.user
    return unless @user.nil?

    raise(MissingUserError,
          I18n.t("assessment.grading_tutorial.no_user_for_config",
                 participation_id: @participation&.id))
  end

  def grading_enabled?
    @assessable.assessable?
  end

  def allow_grading?
    @assessable.grading_open?
  end

  # Points go where the sheet is: a participation a group already holds is not
  # this group's to mark, even if the person has since moved in.
  def elsewhere?
    @tutorial.present? && @participation.tutorial_id.present? &&
      @participation.tutorial_id != @tutorial.id
  end

  # Points go on a sheet that came in; a row nothing was handed in for waits
  # for the mark in the hand-in column first.
  def points_enterable?
    paper_hand_in? && !elsewhere? &&
      !@participation.exempt? && !@participation.absent?
  end

  def status
    @participation.display_status
  end

  def row_id
    return "participation-row-#{@participation.id}" if @participation.persisted?

    "participation-row-user-#{@user.id}"
  end

  def grading_scope_type
    @grading_scope.class.name.downcase
  end

  def save_url
    case @table_option
    when :pointing
      point_participation_path(@participation, grading_scope_type: grading_scope_type)
    when :grading
      grade_participation_path(@participation)
    else
      raise(ArgumentError, "Unsupported table option: #{@table_option}")
    end
  end

  def refresh_url
    case @table_option
    when :pointing
      refresh_point_participation_path(@participation, grading_scope_type: grading_scope_type)
    when :grading
      refresh_grade_participation_path(@participation)
    else
      raise(ArgumentError, "Unsupported table option: #{@table_option}")
    end
  end

  # The hand-in column of a row without a file: whether the sheet came in on
  # paper. The mark can be taken back until points sit on it.
  def paper_hand_in?
    @participation.submitted_at.present?
  end

  # The page's group travels along so the answer comes back in the shape of
  # the table it sits in.
  def paper_hand_in_url
    mark_user_as_participated_path(user_id: @user.id, assignment_id: @assessable.id,
                                   tutorial_id: @tutorial&.id,
                                   grading_scope_type: grading_scope_type)
  end

  def paper_hand_in_removal_url
    remove_participation_path(participation_id: @participation.id,
                              grading_scope_type: grading_scope_type)
  end

  def paper_hand_in_removable?
    graded_task_points.all? { |point| point.points.nil? }
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
        participation_row_target: "pointInput",
        task_id: task.id,
        below_min_message: t("assessment.grading_tutorial.point_below_minimum", min: 0),
        action: "change->participation-row#onParticipationChanged input->participation-row#onParticipationChanged" # rubocop:disable Layout/LineLength
      },
      class: "form-control",
      aria: { label: points_input_label(task) },
      disabled: !allow_grading || !grading_enabled? || !can_enter_points? || !points_enterable?
    )
  end

  def points_input_label(task)
    t("assessment.grading_tutorial.points_input_label",
      task: "#{t("assessment.grading_tutorial.task")} #{task.position}",
      name: @user.tutorial_name)
  end

  def task_points_participation_cell(task, allow_grading)
    tag.td(class: "sticky-col task-col") do
      task_points_participation_input(task, allow_grading)
    end
  end

  # Neutral until the row has something to save; the controller turns it
  # green with the first edit.
  def save_row_button(allow_grading)
    class_name = "btn btn-sm btn-outline-secondary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"

    tag.button(type: "button",
               class: class_name,
               data: { participation_row_target: "save",
                       action: "click->participation-row#saveRow" },
               title: helpers.t("assessment.grading_tutorial.save_row"),
               aria: { label: helpers.t("assessment.grading_tutorial.save_row") },
               disabled: !allow_grading || !grading_enabled? || !can_enter_points?) do
      tag.i(class: "far fa-save")
    end
  end

  def refresh_row_button(allow_grading)
    class_name = "btn btn-sm btn-outline-secondary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"

    tag.button(type: "button",
               class: class_name,
               data: { action: "click->participation-row#refreshRow" },
               title: helpers.t("assessment.grading_tutorial.reload_row"),
               aria: { label: helpers.t("assessment.grading_tutorial.reload_row") },
               disabled: !allow_grading || !grading_enabled? || !can_enter_points?) do
      tag.i(class: "bi bi-arrow-clockwise")
    end
  end

  def can_enter_points?
    user = helpers.current_user
    user.admin? || user.can_enter_points_in?(@grading_scope)
  rescue User::IncompatibleTypeError
    false
  end

  def can_enter_grade?
    user = helpers.current_user
    user.admin? || user.can_enter_grades_in?(@grading_scope)
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

  # -- optional display helpers for the table header and body --

  # if display tasks pointing and total points
  def tasks?
    @config.body_mode.include?(:tasks)
  end

  # if display grade, grade_at, grade_by, note
  def single_grade?
    @config.body_mode.include?(:single_grade)
  end

  # if display tutorial column
  def show_tutorial_col?
    @config.left_columns.include?(:tutorial)
  end

  def show_hand_in_col?
    @config.left_columns.include?(:hand_in)
  end

  # if display correction column
  def show_correction_col?
    @config.right_columns.include?(:correction)
  end

  # ---- task mode helpers ----
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

  # ---- single_grade mode helpers ----

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
end
