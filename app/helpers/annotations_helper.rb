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

  def annotation_index_border_color(annotation, is_student_annotation)
    # The border color of annotation cards shared by students, will be set
    # via JS according to the color of the annotation CATEGORY.
    return "" if is_student_annotation

    "border-color: #{annotation[:color]}"
  end
end
