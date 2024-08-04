class AnnotationsOverviewController < ApplicationController
  layout "application_no_sidebar_with_background"

  def show
    user_annotations = Annotation.where(user_id: current_user.id).map do |annotation|
      {
        category: annotation.category,
        text: annotation.comment_optional,
        link: annotation_open_in_thyme_player_link(annotation),
        color: annotation.color,
        updated_at: annotation.updated_at,
        lecture: annotation.medium.teachable.lecture.title
      }
    end
    @annotations_by_lecture = user_annotations.group_by { |annotation| annotation[:lecture] }
    render "annotations/annotations_overview"
  end

  def annotation_open_in_thyme_player_link(annotation)
    link = helpers.video_link_timed(annotation.medium_id, annotation.timestamp)
    link += "&ann=#{annotation.id}"
    link
  end
end
