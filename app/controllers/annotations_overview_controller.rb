class AnnotationsOverviewController < ApplicationController
  layout "application_no_sidebar_with_background"

  def show
    @user_annotations = Annotation.where(user_id: current_user.id)
    render "annotations/annotations_overview"
  end
end
