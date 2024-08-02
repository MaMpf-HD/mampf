class AnnotationsOverviewController < ApplicationController
  layout "application_no_sidebar_with_background"

  def show
    @annotations = Annotation.all
    render "annotations/annotations_overview"
  end
end
