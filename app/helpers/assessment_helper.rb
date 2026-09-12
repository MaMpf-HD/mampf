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
        participated_tutorial_title: participated_tutorial&.title,
        new_tutorial_title: current_tutorial&.title
      }
    end
  end

  def sticky_css_vars_calc(sticky_layout)
    left = sticky_layout.left_offsets.map { |k, v| "--#{k.to_s.dasherize}-left:#{v}px" }
    right = sticky_layout.right_offsets.map { |k, v| "--#{k.to_s.dasherize}-right:#{v}px" }
    edges = [
      "--sticky-left-width:#{sticky_layout.total_left_width}px",
      "--sticky-right-width:#{sticky_layout.total_right_width}px"
    ]
    (left + right + edges).join(";")
  end

  private

    def overview_frame_src(lecture)
      assessment_assessments_path(lecture_id: lecture.id,
                                  tab: params[:assessment_tab])
    end

    # Three ways a person and their sheet part company: they changed groups,
    # they left the groups, or they joined one after handing in with none.
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
