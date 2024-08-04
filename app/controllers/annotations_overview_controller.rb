class AnnotationsOverviewController < ApplicationController
  layout "application_no_sidebar_with_background"

  def show
    # Own annotations
    user_annotations = Annotation.where(user_id: current_user.id).map do |annotation|
      link = {
        link: annotation_open_in_thyme_player_link(annotation)
      }
      extract_relevant_information(annotation).merge(link)
    end
    @annotations_by_lecture = user_annotations.group_by { |annotation| annotation[:lecture] }
    # TODO: don't include lecture key in the hash anymore after grouping
    # Maybe we can even group in the SQL query directly?

    # Students annotations
    student_annotations = Annotation.where(medium_id: medium_ids_for_teacher_or_editor,
                                           visible_for_teacher: true)
                                    .map do |annotation|
      # TODO: replace by link to Feedback player
      link = {
        link: annotation_open_in_thyme_player_link(annotation)
      }
      extract_relevant_information(annotation).merge(link)
    end
    @student_annotations_by_lecture = student_annotations.group_by do |annotation|
      annotation[:lecture]
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

  def annotation_open_in_thyme_player_link(annotation)
    link = helpers.video_link_timed(annotation.medium_id, annotation.timestamp)
    link += "&ann=#{annotation.id}"
    link
  end
end
