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
      @stack = assignment&.submissions&.where(tutorial: @tutorial)&.proper
                         &.order(:last_modification_by_users_at)
      @non_submitters = assignment&.non_submitters_in_tutorial(@tutorial)
    else
      @lecture = assignment.lecture
      @participations = assignment.assessment&.assessment_participations
      @non_submitters = assignment.non_submitters_in_tutorials
      @non_tutorial_participants = assignment.applicable_users_not_in_tutorials
    end
  end

  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && @assignment.assessable?
  end

  def tasks
    @assignment&.assessment&.persisted_tasks || []
  end

  def total_max_points
    tasks.filter_map(&:max_points).sum
  end

  def grading_records?
    @stack&.any? || @participations&.any? || @non_submitters&.any? do |user|
      user.assessment_participation_in_assignment(@assignment)
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
end
