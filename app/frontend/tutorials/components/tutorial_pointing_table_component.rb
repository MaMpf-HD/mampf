# Pointing table component for the assignment of tutorials
# This includes pointing rows for both by submission and by participation
# Also includes the zone for non-submitters with the possibility to mark them as participated
class TutorialPointingTableComponent < ViewComponent::Base
  def initialize(assignment:, mode:,
                 tutorial: nil)
    super()
    @mode = mode
    @assignment = assignment

    if @mode == "tutor"
      @tutorial = tutorial
      @lecture = @tutorial.lecture
      @stack = assignment&.submissions&.where(tutorial: @tutorial)&.proper
                         &.order(:last_modification_by_users_at)
      @non_submitters = assignment&.non_submitters_in_tutorial(@tutorial)
    else
      @lecture = assignment.lecture
      @tutorials = @lecture.tutorials
      @stack = assignment&.submissions&.proper
                         &.order(:last_modification_by_users_at)
      @submissions_by_tutorial = @stack.group_by(&:tutorial)
      @non_submitters = assignment&.non_submitters_in_tutorials
      @non_submitters_by_tutorial = @non_submitters.group_by do |user|
        user.assessment_participation_in_assignment(assignment)&.tutorial
      end
      @non_tutorial_participants = assignment.applicable_users_not_in_tutorials
    end
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

  # have any grading records for this assignment? (either by submission or by participation)
  def grading_records?
    @stack&.any? || @non_submitters&.any? do |user|
      user.assessment_participation_in_assignment(@assignment)
    end
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
      mode: @mode
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
    @participation = user.assessment_participation_in_assignment(@assignment)
    return unless @participation

    path = remove_participation_path(
      participation_id: @participation.id,
      mode: @mode
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

  # Returns a hash mapping user IDs to their old and new tutorial titles
  # consider only when user has participation record but not in membership
  def users_movement_map
    return {} unless @assignment.past_deadline?

    helpers.users_movement_map_cache[@assignment.id] ||=
      helpers.calculate_user_movement_map_assignment(@assignment, @lecture)
  end

  def non_submitter_status(user)
    movement = users_movement_map[user.id]
    return unless movement

    helpers.non_submitter_status(movement, @tutorial)
  end
end
