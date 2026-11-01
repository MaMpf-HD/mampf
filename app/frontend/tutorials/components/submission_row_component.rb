class SubmissionRowComponent < ViewComponent::Base
  # The table hands its rows the team's participations and the group's
  # non-submitters, read once for the whole page; a row rendered on its own
  # reads them itself.
  # rubocop:disable Metrics/ParameterLists
  def initialize(submission:, assignment:, grading_scope:, participations: nil,
                 addable_members: nil, member_tutorials: nil)
    super()
    @submission = submission
    @tutorial = @submission.tutorial
    @assessment = assignment&.assessment
    @assignment = assignment
    @grading_scope = grading_scope
    @lecture = @assignment.lecture
    @participations = (participations || @submission.participations || []).compact
    @addable_members = addable_members
    @member_tutorials = member_tutorials
  end
  # rubocop:enable Metrics/ParameterLists

  def grading_scope_type
    @grading_scope.class.name.downcase
  end

  # Who came onto the team after the deadline - the hand-in is not late for
  # it, the tutor should just know.
  def joined_late?(user)
    late_joins.key?(user.id)
  end

  # Keeps the marks after a name with its last part, after the last space or
  # hyphen: the team column is narrow, and a mark alone on a line belongs to
  # nobody. The name still wraps between its other parts.
  def name_with_marks(user, &)
    name = user.tutorial_name.to_s
    cut = name.rindex(/[\s-]/)&.succ || 0
    safe_join([name[0...cut],
               tag.span(class: "text-nowrap") { safe_join([name[cut..], capture(&)]) }])
  end

  # Puts everything to know about a member behind one info mark: a change of
  # tutorial since the hand-in, and how they came onto the team later.
  def member_info(user)
    notes = [movement_info_for_user(user)]
    notes << joined_info(user) if joined_late?(user) || tutor_added?(user)
    notes.compact.join(" ").presence
  end

  def tutor_added?(user)
    added_joins.key?(user.id)
  end

  # Says how somebody came onto the team later: after the deadline, or at any
  # time by a tutor, who is then named. A join without added_by may be a
  # tutor's from before that column, so it does not claim the code.
  def joined_info(user)
    join = added_joins[user.id] || late_joins.fetch(user.id)
    time = l(join.created_at, format: :file_time)
    return t("assessment.task_points.joined_late", time: time) unless join.added_by_id?

    t("assessment.task_points.added_by_tutor", tutor: join.added_by.tutorial_name, time: time)
  end

  # Whom the tutor may put on this team: the group's members on no team
  # for this sheet. A hand-in rejected as late takes nobody; it counts as none.
  # Somebody marked on a row of their own is done with the sheet.
  def addable_members
    return [] unless may_add_members? && !team_full?

    @addable_members ||=
      @assignment.non_submitters_in_tutorial(@tutorial)
                 .where.not(id: @assessment.assessment_participations.marked.select(:user_id))
                 .by_last_name
    @addable_members.reject { |member| left_lecture?(member) }
  end

  def may_add_members?
    team_open? && @submission.takes_members?
  end

  # Where teams may span tutorials, members of the others can be put on the
  # team too; the menu asks for them by name, see
  # Assessment::TaskPointsController#add_member_candidates.
  def search_elsewhere?
    may_add_members? && !team_full? && @lecture.cross_tutorial_teams?
  end

  # A full team still opens the menu, which says so rather than offering
  # names the server would refuse.
  def add_member_menu?
    addable_members.any? || search_elsewhere? || (may_add_members? && team_full?)
  end

  def team_full?
    max = @lecture.submission_max_team_size
    max.present? && @submission.users.size >= max
  end

  def add_member_candidates_url
    return unless search_elsewhere?

    add_member_candidates_submission_path(@submission, grading_scope_type: grading_scope_type)
  end

  # Lists those a tutor put on the team, for whoever marks it to take off
  # again. Who joined with the code stays, and so does the last member.
  def removable_members
    return [] unless team_open? && @submission.users.many?
    return [] if added_joins.empty?

    @removable_members ||= @submission.users.where(id: added_joins.keys).by_last_name.to_a
  end

  # A few names are read at a glance; a longer list gets a search field, and
  # so does a menu that searches the other tutorials.
  def member_search?
    addable_members.size > 5 || search_elsewhere?
  end

  # The earliest join founded the team; whether that was late is the
  # triangle's business, not a name's.
  def late_joins
    @late_joins ||= @submission.user_submission_joins.sort_by(&:created_at).drop(1)
                               .select { |join| join.created_at > @assignment.deadline }
                               .index_by(&:user_id)
  end

  def added_joins
    @added_joins ||= @submission.user_submission_joins.select(&:added_by_id?)
                                .index_by(&:user_id)
  end

  def grading_enabled?
    @assessment.present?
  end

  # The menus follow the server: a tutor changes a team only while points
  # can be entered.
  def team_open?
    can_enter_points? && grading_enabled? && @assignment.grading_open?
  end

  def layout
    @layout ||= MarkingTableLayout.for(assessable: @assignment, grading_scope: @grading_scope)
  end

  def allow_grading?
    !elsewhere? && @submission.valid_for_marking? && @assignment&.grading_open?
  end

  def elsewhere?
    @grading_scope.is_a?(Tutorial) && @grading_scope != @tutorial
  end

  def marked_elsewhere_info
    t("assessment.task_points.marked_elsewhere", tutorial: @tutorial.title_with_tutors)
  end

  # Uses the students' tutorials the table read once for the page; a row
  # rendered on its own asks the submission.
  def hand_over_targets
    return [] if elsewhere? || !@tutorial.correctable_by?(helpers.current_user)
    return @submission.hand_over_targets.to_a unless @member_tutorials
    return [] unless @submission.users.many? && movable?

    @submission.users.filter_map { |user| @member_tutorials[user.id] }
               .uniq.excluding(@tutorial).sort_by(&:title)
  end

  # A tutor of another tutorial reads the team for their own students; the
  # others' addresses are not theirs to collect.
  def copy_emails
    return @submission.users.map(&:email) unless elsewhere?

    own = if @member_tutorials
      @submission.users.select { |user| @member_tutorials[user.id] == @grading_scope }
    else
      @submission.users.where(id: @grading_scope.tutorial_memberships.select(:user_id))
    end
    own.map(&:email)
  end

  def tasks
    @assessment.persisted_tasks || []
  end

  def movable?
    @submission.correction.blank? &&
      @participations.none? { |participation| @assessment&.marked?(participation) }
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
        max_points: task.max_points,
        over_max_message: t("assessment.grading_tutorial.point_over_maximum",
                            max: helpers.number_with_precision(task.max_points,
                                                               strip_insignificant_zeros: true)),
        action: "change->participation-row#onPointSubmissionChanged input->participation-row#onPointSubmissionChanged" # rubocop:disable Layout/LineLength
      },
      class: "form-control",
      aria: { label: points_input_label(task) },
      disabled: !allow_grading
    )
  end

  def points_input_label(task)
    t("assessment.grading_tutorial.points_input_label",
      task: task.label,
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
    uploaded_at = submission.last_modification_by_users_at || submission.created_at
    text = t("assessment.task_points.late_submission",
             time: l(uploaded_at, format: :file_time))
    return text unless submission.accepted.nil? && helpers.current_user.in?(tutorial.tutors)

    "#{text} #{t("tutorial.late_submission_decision").strip}"
  end

  def can_enter_points?
    return false if elsewhere?

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

  def left_lecture?(user)
    @lecture.left_user_ids.include?(user.id)
  end
end
