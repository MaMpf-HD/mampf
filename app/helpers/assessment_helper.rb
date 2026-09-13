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
    participations = assignment.assessment&.assessment_participations
                               &.includes(:tutorial)&.to_a
    return {} if participations.nil?

    current_tutorials = lecture.tutorials.includes(:tutorial_memberships)
                               .each_with_object({}) do |tutorial, map|
      tutorial.tutorial_memberships.each { |m| map[m.user_id] = tutorial }
    end
    participations_by_user = participations.index_by(&:user_id)

    user_ids = participations_by_user.keys | current_tutorials.keys
    user_ids.each_with_object({}) do |user_id, result|
      current_tutorial = current_tutorials[user_id]
      participation = participations_by_user[user_id]
      participated_tutorial = participation&.tutorial

      result[user_id] = {
        participated_tutorial_id: participated_tutorial&.id,
        new_tutorial_id: current_tutorial&.id,
        submitted_at: participation&.submitted_at,
        participated_tutorial_title: participated_tutorial&.title,
        new_tutorial_title: current_tutorial&.title
      }
    end
  end

  private

    def overview_frame_src(lecture)
      assessment_assessments_path(lecture_id: lecture.id,
                                  tab: params[:assessment_tab])
    end

    # The sheet stays with the group that has it; the wording has to say where
    # it is and where the person is now.
    def movement_msg_assignment(movement)
      old_title = movement[:participated_tutorial_title]
      new_title = movement[:new_tutorial_title]
      if movement[:participated_tutorial_id].nil?
        t("assessment.grading_tutorial.user_joined_tutorial", new_tutorial: new_title)
      elsif movement[:new_tutorial_id].nil?
        t("assessment.grading_tutorial.user_left_tutorials", old_tutorial: old_title)
      else
        t("assessment.grading_tutorial.user_moved_tutorial",
          old_tutorial: old_title, new_tutorial: new_title)
      end
    end
end
