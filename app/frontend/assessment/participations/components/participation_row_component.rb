# Renders a participation's assignment task points or talk grade.
class ParticipationRowComponent < ViewComponent::Base
  class MissingUserError < StandardError; end

  ROW_ACTION_CLASSES = "btn btn-sm btn-link row-action text-secondary d-inline-flex " \
                       "align-items-center justify-content-center px-2 py-1 lh-1 fs-5".freeze

  # Assignment participations may be unsaved until AssessmentBackfillWorker
  # runs or a paper hand-in is recorded.
  # What a grade scheme would give the row, and how to explain it.
  Proposal = Struct.new(:grade, :tooltip, keyword_init: true)

  # rubocop:disable Metrics/ParameterLists
  def initialize(participation:, assessment:, grading_scope:, table_option: :pointing,
                 proposal: nil, filter_tutorial_id: nil)
    super()
    @participation = participation
    @assessment = assessment
    @assessable = assessment.assessable
    @grading_scope = grading_scope
    @table_option = table_option
    @proposal = proposal
    @filter_tutorial_id = filter_tutorial_id
    @user ||= @participation&.user
    @tutorial = (@grading_scope if @grading_scope.is_a?(Tutorial))

    return unless @user.nil?

    raise(MissingUserError,
          I18n.t("assessment.grading_tutorial.no_user_for_config",
                 participation_id: @participation&.id))
  end
  # rubocop:enable Metrics/ParameterLists

  def grading_enabled?
    @assessment.persisted?
  end

  def layout
    @layout ||= PointingTableLayout.for(assessable: @assessable, grading_scope: @grading_scope,
                                        table_option: @table_option)
  end

  def tasks?
    layout.body == :tasks
  end

  def single_grade?
    layout.body == :single_grade
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
  # for the mark in the hand-in column first. An exam has nothing to hand in.
  # Entering test points records participation; no separate hand-in is needed.
  def points_enterable?
    return false if @participation.exempt? || @participation.absent?
    return true if @assessable.is_a?(Exam)

    (paper_hand_in? || test?) && !elsewhere?
  end

  def test?
    @assessable.is_a?(Assignment) && @assessable.kind_test?
  end

  # Somebody absent or excused has no grade to enter; what a scheme gave
  # them stays readable.
  def grade_enterable?
    !@participation.exempt? && !@participation.absent?
  end

  def exam_grading?
    @assessable.is_a?(Exam) && @table_option == :grading
  end

  # A greyed-out field needs its reason in sight, not in a tooltip.
  def locked_reason
    if elsewhere?
      t("assessment.grading_tutorial.held_by", tutorial: @participation.tutorial.title)
    elsif status == :awaiting_record && can_enter_points? && !test?
      t("assessment.grading_tutorial.record_first")
    end
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

  def status
    @participation.display_status
  end

  def talk_dates
    return nil if @assessable.dates.blank?

    @assessable.dates.sort.map { |date| I18n.l(date, format: :concise) }.join(", ")
  end

  # Beyond its state, a row can be in a spot the filter should find.
  def filter_flags
    @participation.points_changed_after_grading? ? "points_changed" : ""
  end

  # A sheet's row belongs to the tutorial that graded it; an exam's row to
  # the tutorial the candidate attends, which the table looks up.
  def filter_tutorial_id
    @filter_tutorial_id || @participation.tutorial_id
  end

  def filter_name
    [(@assessable.title if layout.show?(:talk)), @user.tutorial_name].compact.join(" ")
  end

  # An exam draws the same participation in two tables on one page, so the
  # id carries the table.
  def row_id
    return "#{@table_option}-participation-row-#{@participation.id}" if @participation.persisted?

    "#{@table_option}-participation-row-user-#{@user.id}"
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

  # Points taken out again leave a total of 0, not nil; the row says "—"
  # like the student's page does until a task carries a value.
  def points_total_display
    return "—" unless @participation.results_visible?

    helpers.number_with_precision(@participation.points_total, precision: 2)
  end

  def proposed_grade
    @proposal&.grade&.to_s
  end

  def proposal_tooltip
    @proposal&.tooltip
  end

  def proposed_grade_differs?
    @proposal&.grade.present? && @proposal.grade != grade_numeric
  end

  # A graded row keeps its grade when a point is taken out again; the
  # notice says so, since the status alone reads as complete.
  def points_changed_notice
    return unless @participation.points_changed_after_grading?

    since = t("assessment.grading_exam.points_changed_since",
              points_at: I18n.l(@participation.task_points.map(&:updated_at).max,
                                format: :file_time),
              graded_at: I18n.l(@participation.graded_at, format: :file_time))
    return since if @participation.all_tasks_scored?

    "#{since} · #{t("assessment.grading_exam.points_missing")}"
  end

  def absence_button
    return unless can_enter_points?
    return if test? && elsewhere?

    if @participation.absent?
      row_action_link(remove_absent_path(@participation, grading_scope_type: grading_scope_type),
                      "bi-person-check-fill", t("assessment.grading_exam.remove_absent"))
    elsif @participation.pending? && absence_recordable?
      row_action_link(mark_as_absent_path(@participation, grading_scope_type: grading_scope_type),
                      "bi-person-x-fill", t("assessment.grading_exam.mark_absent"))
    end
  end

  # Absence is the grader's to record, an exemption the lecturer's - it takes
  # a certificate and changes what counts. On a test, from its Monday and
  # while no points were started; taking an absence back is offered whatever
  # the week says, so a test moved to a later week does not leave one standing.
  def absence_recordable?
    !test? || (allow_grading? && !paper_hand_in?)
  end

  # Certificates can arrive after absence was recorded. mark_exempt clears
  # the failing grade, so an absent row can be exempted directly.
  def exemption_button
    return unless helpers.current_user.can_edit?(@assessable.lecture)

    if @participation.exempt?
      row_action_link(remove_exempt_path(@participation), "bi-file-earmark-x-fill",
                      t("assessment.grading_exam.remove_exempt"))
    elsif @participation.pending? || @participation.absent?
      label = t("assessment.grading_exam.mark_exempt")
      tag.button(type: "button",
                 class: ROW_ACTION_CLASSES,
                 data: { action: "click->participation-row#openExemptModal",
                         url: mark_as_exempt_path(@participation),
                         note: @participation.note },
                 title: label,
                 aria: { label: label }) do
        tag.i(class: "bi bi-file-earmark-medical-fill")
      end
    end
  end

  def row_action_link(url, icon, label)
    link_to(url, class: ROW_ACTION_CLASSES, data: { turbo_method: :patch },
                 title: label, aria: { label: label }) do
      tag.i(class: "bi #{icon}")
    end
  end

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
    tag.td(class: layout.column_class(:task)) do
      task_points_participation_input(task, allow_grading)
    end
  end

  def save_row_button(allow_grading)
    class_name = "btn btn-sm btn-link text-body-tertiary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1 fs-5"

    tag.button(type: "button",
               class: class_name,
               data: { participation_row_target: "save",
                       action: "click->participation-row#saveRow" },
               title: row_action_label("save_row"),
               aria: { label: row_action_label("save_row") },
               disabled: !allow_grading || !grading_enabled? || !can_enter_row?) do
      tag.i(class: "bi bi-floppy-fill")
    end
  end

  def refresh_row_button(allow_grading)
    class_name = "btn btn-sm btn-link row-action text-secondary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1 fs-5"

    tag.button(type: "button",
               class: class_name,
               data: { action: "click->participation-row#refreshRow" },
               title: row_action_label("reload_row"),
               aria: { label: row_action_label("reload_row") },
               disabled: !allow_grading || !grading_enabled? || !can_enter_row?) do
      tag.i(class: "bi bi-arrow-counterclockwise")
    end
  end

  def row_action_label(action)
    scope = single_grade? ? "assessment.grade_talk_row" : "assessment.grading_tutorial"
    helpers.t("#{scope}.#{action}")
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

  def can_enter_row?
    single_grade? ? can_enter_grade? : can_enter_points?
  end

  def users_movement_map
    helpers.users_movement_map_cache[@assessable.id] ||=
      helpers.calculate_user_movement_map_assignment(@assessable, @assessable.lecture)
  end

  # Tutorial movement compares a sheet's participation with the user's
  # tutorial membership; a talk or an exam has nothing handed in to compare.
  def movement_info_for_user(user)
    return nil unless @assessable.is_a?(Assignment)

    helpers.movement_info_for_user_assignment(user, users_movement_map)
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

  # Who graded and when, on one line; the date is a record, the tooltip says
  # how long ago that was.
  def graded_display
    return nil unless @participation&.graded_at

    [grader_display, I18n.l(@participation.graded_at, format: :file_time)].compact.join(" · ")
  end

  # What the compact status icon says on hover: who graded and when, or why
  # somebody is excused.
  def status_detail
    return "#{graded_display} (#{graded_ago})" if graded_display
    return @participation.note if @participation.exempt? && @participation.note.present?

    nil
  end

  def graded_ago
    return nil unless @participation&.graded_at

    t("assessment.grade_talk_row.graded_ago",
      time: helpers.time_ago_in_words(@participation.graded_at))
  end
end
