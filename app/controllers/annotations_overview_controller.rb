class AnnotationsOverviewController < ApplicationController
  layout "application_no_sidebar_with_background"

  def show
    user_annotations = Annotation.where(user_id: current_user.id).map do |annotation|
      link = { link: annotation_open_link(annotation) }
      extract_relevant_information(annotation).merge(link)
    end
    @annotations_by_lecture = user_annotations.group_by { |annotation| annotation[:lecture] }
    # TODO: don't include lecture key in the hash anymore after grouping
    # Maybe we can even gruop in the SQL query directly?

    @show_students_annotations = current_user.teachable_editor_or_teacher?
    if @show_students_annotations
      student_annotations = Annotation.where(medium_id: medium_ids_for_teacher_or_editor,
                                             visible_for_teacher: true)
                                      .map do |annotation|
        link = { link: annotation_open_link(annotation, in_feedback_player: true) }
        extract_relevant_information(annotation).merge(link)
      end
      @student_annotations_by_lecture = student_annotations.group_by do |annotation|
        annotation[:lecture]
      end
    end

    render "annotations/annotations_overview"
  end

  def extract_relevant_information(annotation)
    {
      category: annotation.category,
      text: annotation.comment_optional,
      color: annotation.color,
      updated_at: annotation.updated_at,
      lecture: annotation.medium.teachable.lecture.title
    }
  end

  def medium_ids_for_teacher_or_editor
    lectures = current_user.given_lectures + current_user.edited_lectures
    lectures.map(&:media_with_inheritance).flatten.pluck(:id)
  end

  def annotation_open_link(annotation, in_feedback_player: false)
    link = if in_feedback_player
      helpers.feedback_video_link_timed(annotation.medium_id, annotation.timestamp)
    else
      helpers.video_link_timed(annotation.medium_id, annotation.timestamp)
    end

    link += "&ann=#{annotation.id}"
    link
  end
end
