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

  def movement_info_for_user_assignment(user, user_movement_map)
    movement = user_movement_map[user.id]
    return nil unless movement

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

  # When tutorials differ, keep point entry with participated_tutorial_id.
  # Recreating a participation would use the current tutorial membership;
  # a nil host_tutorial allows point entry for the whole lecture.
  def non_submitter_status(movement, host_tutorial)
    return unless movement

    if never_participated?(movement)
      {
        allowed: true,
        mark_participation_allow: true,
        message: t("assessment.grading_tutorial.no_submission_badge")
      }
    elsif participation_matches_membership?(movement)
      if movement[:submitted_at].nil?
        {
          allowed: true,
          remove_participation_allow: false,
          message: t("assessment.grading_tutorial.no_submission_badge")
        }
      else
        {
          allowed: true,
          remove_participation_allow: true,
          message: t("assessment.grading_tutorial.marked_as_participated_badge")
        }
      end
    elsif participation_differs_from_membership_lecture_mode?(host_tutorial)
      {
        allowed: true,
        message: t("assessment.grading_tutorial.no_submission_badge") +
          movement_msg_assignment(movement)
      }
    elsif moved_into_host_tutorial?(movement, host_tutorial)
      {
        allowed: false,
        message: movement_msg_assignment(movement)
      }
    elsif participated_in_host_tutorial?(movement, host_tutorial) # rubocop:disable Lint/DuplicateBranch
      {
        allowed: true,
        message: t("assessment.grading_tutorial.no_submission_badge") +
          movement_msg_assignment(movement)
      }
    end
  end

  private

    def overview_frame_src(lecture)
      assessment_assessments_path(lecture_id: lecture.id,
                                  tab: params[:assessment_tab])
    end

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
