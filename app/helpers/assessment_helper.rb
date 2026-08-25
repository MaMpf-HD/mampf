# Helpers for the assessment area of the lecture edit page.
module AssessmentHelper
  include Rosters::UsersMovementCaching

  # The assessment tab shows the overview of all assessables, or the dashboard
  # of the one the URL names. The latter is what makes a dashboard link work
  # when it is opened in a new tab instead of clicked.
  def assessment_frame_src(lecture)
    return overview_frame_src(lecture) if params[:assessment_id].blank?

    assessment_assessment_path(params[:assessment_id],
                               assessable_type: params[:assessable_type],
                               assessable_id: params[:assessable_id],
                               tab: params[:assessment_tab])
  end

  # A "non-submitter" is a student who hasn't submitted anything for this assignment,
  # but may still be gradable based on their participation/membership history.
  #
  # movement[:participated_tutorial_id] = tutorial where their participation record lives (if any)
  # movement[:new_tutorial_id] = tutorial they currently belong to (membership)
  #
  # host_tutorial is nil in "lecture mode" (grading isn't scoped to one tutorial),
  # or set in "tutorial mode" (grading is scoped to a specific tutorial).

  def movement_info_for_user_assignment(user, user_movement_map)
    movement = user_movement_map[user.id]
    return nil unless movement

    # only display a message if the user has moved tutorials since their participation was recorded
    return unless movement[:participated_tutorial_id] != movement[:new_tutorial_id]

    movement_msg_assignment(movement)
  end

  def calculate_user_movement_map_assignment(assignment, lecture)
    tutorial_memberships = lecture.tutorials
                                  .includes(:tutorial_memberships)
                                  .flat_map(&:tutorial_memberships)
    participations = assignment.assessment&.assessment_participations&.to_a
    return {} if participations.nil?

    participation_user_ids = participations.map(&:user_id)
    member_user_ids = tutorial_memberships.map(&:user_id)

    ids = (participation_user_ids | member_user_ids)

    ids.each_with_object({}) do |user_id, result|
      current_tutorial = tutorial_memberships.find { |m| m.user_id == user_id }&.tutorial
      participation = participations.find { |p| p.user_id == user_id }
      participated_tutorial = participation&.tutorial

      result[user_id] = {
        participated_tutorial_id: participated_tutorial&.id,
        new_tutorial_id: current_tutorial&.id,
        submitted_at: participation&.submitted_at,
        participated_tutorial_title: participated_tutorial&.title ||
                                     t("assessment.grading_tutorial.no_tutorial"),
        new_tutorial_title: current_tutorial&.title ||
                            t("assessment.grading_tutorial.no_tutorial")
      }
    end
  end

  def non_submitter_status(movement, host_tutorial)
    return unless movement

    if never_participated?(movement)
      # No participation record in ANY tutorial for this assignment.
      # The only reason they're being considered here is their current membership.
      # -> allowed to be graded, and can be marked as participated first
      #    (after which they become gradable as a normal participant)
      {
        allowed: true,
        mark_participation_allow: true,
        message: t("assessment.grading_tutorial.no_submission_badge")
      }
    elsif participation_matches_membership?(movement)
      # Has both a participation record AND current membership in this same tutorial.
      # a grade entry already exists
      # -- because backfill (submitted_at == nil) or marked as participated (submitted_at != nil)
      # -> allowed, and the participation can be removed (for marked as participated case)
      {
        allowed: true,
        remove_participation_allow: movement[:submitted_at].present?,
        message: t("assessment.grading_tutorial.marked_as_participated_badge")
      }
    elsif participation_differs_from_membership_lecture_mode?(host_tutorial)
      # participated_tutorial_id and new_tutorial_id are both present but differ
      # -> membership has moved since participation was recorded.
      #
      # Lecture mode (no host tutorial context) -> always allow grading.
      #
      # removing and recreating participation here would be risky,
      # since a newly created participation record would follow the current membership,
      # not the tutorial where they actually participated.
      {
        allowed: true,
        message: t("assessment.grading_tutorial.no_submission_badge") +
          movement_msg_assignment(movement)
      }
    elsif moved_into_host_tutorial?(movement, host_tutorial)
      # participated_tutorial_id and new_tutorial_id are both present but differ
      # -> membership has moved since participation was recorded.
      #
      # Tutorial mode. Host tutorial matches the NEW (current membership) tutorial,
      # they participated in a different tutorial, then their membership was moved into this one
      #
      # -> not allowed to be graded here
      {
        allowed: false,
        message: movement_msg_assignment(movement)
      }
    elsif participated_in_host_tutorial?(movement, host_tutorial) # rubocop:disable Lint/DuplicateBranch
      # participated_tutorial_id and new_tutorial_id are both present but differ
      # -> membership has moved since participation was recorded.
      #
      # Tutorial mode. Host tutorial matches the OLD (participation) tutorial,
      # meaning: they participated here, but their membership has since moved elsewhere.
      #
      # -> allowed to be graded here
      # removing participation is still risky as
      # a recreated record would follow the current membership, not this tutorial.
      {
        allowed: true,
        message: t("assessment.grading_tutorial.no_submission_badge") +
          movement_msg_assignment(movement)
      }
    end
  end

  private

    def never_participated?(movement)
      movement[:participated_tutorial_id].nil?
    end

    def participation_matches_membership?(movement)
      movement[:participated_tutorial_id] == movement[:new_tutorial_id]
    end

    def participation_differs_from_membership_lecture_mode?(host_tutorial)
      host_tutorial.nil?
    end

    def moved_into_host_tutorial?(movement, host_tutorial)
      host_tutorial.id == movement[:new_tutorial_id]
    end

    def participated_in_host_tutorial?(movement, host_tutorial)
      host_tutorial.id == movement[:participated_tutorial_id]
    end

    def movement_msg_assignment(movement)
      t("assessment.grading_tutorial.user_moved_tutorial",
        old_tutorial: movement[:participated_tutorial_title] ||
                                  t("assessment.grading_tutorial.no_tutorial"),
        new_tutorial: movement[:new_tutorial_title] || t("assessment.grading_tutorial.no_tutorial"))
    end
end
