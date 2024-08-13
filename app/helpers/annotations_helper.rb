module AnnotationsHelper
  def annotation_open_link(annotation, is_shared)
    link = if is_shared
      feedback_video_link_timed(annotation.medium_id, annotation.timestamp)
    else
      video_link_timed(annotation.medium_id, annotation.timestamp)
    end
    link += "&ann=#{annotation.id}"
    link
  end
end
