class AnnotationsOverviewController < ApplicationController
  layout "application_no_sidebar_with_background"

  def show
    user_annotations = Annotation.where(user_id: current_user.id).map do |annotation|
      lecture_name = annotation.medium.teachable.lecture.title

      link = helpers.video_link_timed(annotation.medium_id, annotation.timestamp)
      link += "&ann=#{annotation.id}"
      {
        category: annotation.category,
        text: annotation.comment_optional,
        link: link,
        color: annotation.color,
        updated_at: annotation.updated_at,
        lecture: lecture_name
      }
    end

    @annotations_by_lecture = user_annotations.group_by { |annotation| annotation[:lecture] }

    render "annotations/annotations_overview"
  end
end
