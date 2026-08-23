# Helpers for the assessment area of the lecture edit page.
module AssessmentHelper
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

    movement_info_for_user_assignment_msg(movement[:old_tutorial_title],
                                          movement[:new_tutorial_title])
  end

  def movement_info_for_user_assignment_msg(old_tutorial_title, new_tutorial_title)
    t("assessment.grading_tutorial.user_moved_tutorial",
      old_tutorial: old_tutorial_title || t("assessment.grading_tutorial.no_tutorial"),
      new_tutorial: new_tutorial_title || t("assessment.grading_tutorial.no_tutorial"))
  end

  def calculate_user_movement_map_assignment(assignment, lecture)
    tutorial_memberships = lecture.tutorials
                                  .includes(:tutorial_memberships)
                                  .flat_map(&:tutorial_memberships)
    participations = assignment.assessment&.assessment_participations&.to_a
    return {} if participations.nil?

    participation_user_ids = participations.map(&:user_id)
    member_user_ids = tutorial_memberships.map(&:user_id)

    ids = (participation_user_ids | member_user_ids) - (participation_user_ids & member_user_ids)

    ids.each_with_object({}) do |user_id, result|
      current_tutorial = tutorial_memberships.find { |m| m.user_id == user_id }&.tutorial
      old_tutorial = participations.find { |p| p.user_id == user_id }&.tutorial
      next unless current_tutorial&.id != old_tutorial&.id

      result[user_id] = {
        old_tutorial_id: old_tutorial&.id,
        new_tutorial_id: current_tutorial&.id,
        old_tutorial_title: old_tutorial&.title ||
                            t("assessment.grading_tutorial.no_tutorial"),
        new_tutorial_title: current_tutorial&.title ||
                            t("assessment.grading_tutorial.no_tutorial")
      }
    end
  end

  def non_submitter_status(movement, host_tutorial)
    return unless movement

    if movement[:old_tutorial_id].nil?
      # non-submitter + no participartion -> late submitter
      # -> allowed
      t("assessment.grading_tutorial.no_submission_badge")
    elsif host_tutorial.id == movement[:new_tutorial_id]
      # -> non-submitter  + membership in this tutorial for this assignment
      #                   + no participation in this tutorial for this assignment
      # -> has been moved to this tutorial after having participation in other tutorial
      # -> not allowed to be graded here
      movement_info_for_user_assignment_msg(
        movement[:old_tutorial_title],
        movement[:new_tutorial_title]
      )
    else
      # -> non-submitter  + has participation in this tutorial for this assignment
      #                   + currently not in this tutorial membership
      #
      # only possible if he used to be in this tutorial and has participation record
      # from the background fill, or the tutor has explicitly marked him as participated,
      # but now he has been moved to another tutorial
      t("assessment.grading_tutorial.no_submission_badge") +
        movement_info_for_user_assignment_msg(
          movement[:old_tutorial_title],
          movement[:new_tutorial_title]
        )
    end
  end

  private

    def overview_frame_src(lecture)
      assessment_assessments_path(lecture_id: lecture.id,
                                  tab: params[:assessment_tab])
    end
end
