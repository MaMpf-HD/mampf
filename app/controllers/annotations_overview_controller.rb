class AnnotationsOverviewController < ApplicationController
  layout "application_no_sidebar_with_background"

  def show
    @user_annotations = Annotation.where(user_id: current_user.id).map do |annotation|
      link = helpers.video_link_timed(annotation.medium_id, annotation.timestamp)
      link += "&ann=#{annotation.id}"
      {
        category: annotation.category,
        text: annotation.comment_optional,
        link: link,
        color: annotation.color,
        updated_at: annotation.updated_at
      }
    end
    render "annotations/annotations_overview"
  end
end
