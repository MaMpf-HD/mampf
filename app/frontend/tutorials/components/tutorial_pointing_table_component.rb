class TutorialPointingTableComponent < ViewComponent::Base
  def initialize(assignment:, grading_scope: nil)
    super()
    @assignment = assignment
    @lecture = assignment.lecture
    @grading_scope = grading_scope
    if grading_scope.is_a?(Tutorial)
      @tutorial = @grading_scope
      init_tutor_case
    elsif grading_scope.is_a?(Lecture)
      init_teacher_case
    end
  end

  def init_tutor_case
    @mode = "tutor"
    @stack = @assignment.submissions.where(tutorial: @tutorial).proper
                        .order(:last_modification_by_users_at)
                        .includes(:users, tutorial: :tutors)
    @non_submitters = @assignment&.non_submitters_in_tutorial(@tutorial)
    @participations_by_user_id = preload_participations(@non_submitters, @stack)
  end

  def init_teacher_case
    @mode = "teacher"
    @tutorials = @lecture.tutorials
    @stack = @assignment.submissions.proper
                        .order(:last_modification_by_users_at)
                        .includes(:users, tutorial: :tutors)
    @submissions_by_tutorial = @stack.group_by(&:tutorial)

    @non_submitters = @assignment&.non_submitters_in_tutorials
    @participations_by_user_id = preload_participations(@non_submitters, @stack)

    @non_tutorial_participants = @assignment.applicable_users_not_in_tutorials

    @non_submitters_by_tutorial = @non_submitters.group_by do |user|
      @participations_by_user_id[user.id]&.tutorial
    end
  end

  # Preload each submission team's participations and task_points to avoid
  # queries per submission.
  def preload_participations(non_submitters, submissions)
    return {} unless @assignment.assessment

    user_ids = non_submitters.map(&:id) + submissions.flat_map(&:user_ids)
    Assessment::Participation
      .where(user_id: user_ids, assessment: @assignment.assessment)
      .includes(:task_points)
      .index_by(&:user_id)
  end

  def team_participations(submission)
    submission.users.map { |user| @participations_by_user_id[user.id] }
  end

  def grading_enabled?
    @assignment.assessable?
  end

  def tasks
    @assignment&.assessment&.persisted_tasks || []
  end

  def total_max_points
    @assignment&.assessment&.effective_total_points || 0
  end

  def grading_records?
    @stack&.any? || @non_submitters&.any? { |user| @participations_by_user_id[user.id] }
  end

  def column_count
    if @mode == "tutor"
      6 + tasks.count
    else
      5 + tasks.count
    end
  end

  LINK_STYLE = "display:inline-flex; align-items:center; gap:4px; " \
               "padding:4px 10px; border-radius:6px; " \
               "border:1px solid #e0e0e0; background:#fff; " \
               "font-size:12px; color:#555; text-decoration:none;".freeze

  def mark_as_participated_link(user)
    path = mark_user_as_participated_path(
      user_id: user.id,
      assignment_id: @assignment.id,
      grading_scope_type: @grading_scope.class.name.downcase
    )

    link_to(path,
            style: LINK_STYLE,
            data: { turbo_method: :patch,
                    turbo_confirm: t("assessment.grading_tutorial.confirm_unsaved_changes") }) do
      safe_join([
                  content_tag(:span, "check", class: "material-icons", style: "font-size: 14px;"),
                  t("assessment.grading_tutorial.mark_as_participated")
                ])
    end
  end

  def remove_participated_link(user)
    participation = @participations_by_user_id[user.id]
    return unless participation

    path = remove_participation_path(
      participation_id: participation.id,
      grading_scope_type: @grading_scope.class.name.downcase
    )

    link_to(path,
            style: LINK_STYLE,
            data: { turbo_method: :patch,
                    turbo_confirm: t("assessment.grading_tutorial.confirm_unsaved_changes") }) do
      safe_join([
                  content_tag(:span, "close", class: "material-icons", style: "font-size: 14px;"),
                  t("assessment.grading_tutorial.remove_participated")
                ])
    end
  end

  def users_movement_map
    helpers.users_movement_map_cache[@assignment.id] ||=
      helpers.calculate_user_movement_map_assignment(@assignment, @lecture)
  end

  def non_submitter_status(user)
    movement = users_movement_map[user.id]
    return unless movement

    helpers.non_submitter_status(movement, @tutorial)
  end
end
