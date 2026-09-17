class SubmissionRowComponent < ViewComponent::Base
  # The table hands its rows the team's participations and the group's
  # non-submitters, read once for the whole page; a row rendered on its own
  # reads them itself.
  def initialize(submission:, assignment:, grading_scope:, participations: nil,
                 addable_members: nil)
    super()
    @submission = submission
    @tutorial = @submission.tutorial
    @assessment = assignment&.assessment
    @assignment = assignment
    @grading_scope = grading_scope
    @lecture = @assignment.lecture
    @participations = (participations || @submission.participations || []).compact
    @addable_members = addable_members
  end

  def grading_scope_type
    @grading_scope.class.name.downcase
  end

  # Who came onto the team after the deadline - the hand-in is not late for
  # it, the tutor should just know.
  def joined_late?(user)
    late_joins.key?(user.id)
  end

  def joined_late_info(user)
    t("assessment.task_points.joined_late",
      time: l(late_joins.fetch(user.id).created_at, format: :file_time))
  end

  # Whom the tutor may put on this team: the group's members on no team
  # for this sheet. A rejected hand-in takes nobody; it counts as none.
  def addable_members
    return [] unless can_enter_points? && grading_enabled? && @submission.accepted != false

    @addable_members ||= @assignment.non_submitters_in_tutorial(@tutorial)
    @addable_members.sort_by { |member| member.tutorial_name.to_s.downcase }
  end

  def late_joins
    @late_joins ||= @submission.user_submission_joins
                               .select { |join| join.created_at > @assignment.deadline }
                               .index_by(&:user_id)
  end

  def grading_enabled?
    @assessment.present?
  end

  def layout
    @layout ||= MarkingTableLayout.for(assessable: @assignment, grading_scope: @grading_scope)
  end

  def allow_grading?
    @submission.valid_for_marking? && @assignment&.grading_open?
  end

  def tasks
    @assessment.persisted_tasks || []
  end

  # A team is marked as one - every member gets the same points and the same
  # status - so the first participation there is speaks for the row.
  def participation
    @participations.first
  end

  def status
    participation&.display_status
  end

  def late?
    @submission.too_late?
  end

  def row_id
    "submission-row-#{@submission.id}"
  end

  def extract_task_points(task)
    participation&.task_points&.find { |task_point| task_point.task_id == task.id }&.points
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
        participation_row_target: "pointInput",
        task_id: task.id,
        below_min_message: t("assessment.grading_tutorial.point_below_minimum", min: 0),
        action: "change->participation-row#onPointSubmissionChanged input->participation-row#onPointSubmissionChanged" # rubocop:disable Layout/LineLength
      },
      class: "form-control",
      aria: { label: points_input_label(task) },
      disabled: !allow_grading
    )
  end

  def points_input_label(task)
    t("assessment.grading_tutorial.points_input_label",
      task: "#{t("assessment.grading_tutorial.task")} #{task.position}",
      name: @submission.users.map(&:tutorial_name).join(", "))
  end

  def task_points_cell(task, allow_grading)
    tag.td(class: layout.column_class(:task)) do
      task_points_input(task, allow_grading)
    end
  end

  def save_row_button(allow_grading)
    class_name = "btn btn-sm btn-link text-body-tertiary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1 fs-5"

    tag.button(type: "button",
               class: class_name,
               data: { participation_row_target: "save",
                       action: "click->participation-row#saveRow" },
               title: helpers.t("assessment.grading_tutorial.save_row"),
               aria: { label: helpers.t("assessment.grading_tutorial.save_row") },
               disabled: !allow_grading) do
      tag.i(class: "bi bi-floppy-fill")
    end
  end

  def refresh_row_button(allow_grading)
    class_name = "btn btn-sm btn-link row-action text-secondary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1 fs-5"

    tag.button(type: "button",
               class: class_name,
               data: { action: "click->participation-row#refreshRow" },
               title: helpers.t("assessment.grading_tutorial.reload_row"),
               aria: { label: helpers.t("assessment.grading_tutorial.reload_row") },
               disabled: !allow_grading) do
      tag.i(class: "bi bi-arrow-counterclockwise")
    end
  end

  def late_submission_info(submission, tutorial)
    text = t("submission.late")
    return text unless submission.accepted.nil? && helpers.current_user.in?(tutorial.tutors)

    "#{text} (#{t("tutorial.late_submission_decision")})"
  end

  def can_enter_points?
    user = helpers.current_user
    user.admin? || user.can_enter_points_in?(@grading_scope)
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
