# Establishes the initial scope of media for a lecture's index page.
#
# This filter finds all media for a given "project" (a Medium sort) that are
# associated with the given lecture, its lessons, or its parent course.
module Search
  module Filters
    class LectureMediaScopeFilter < BaseFilter
      def call
        lecture_id = params[:lecture_id]
        project = params[:project]

        return scope.none unless lecture_id && project.present?

        lecture = Lecture.find_by(id: lecture_id)
        return scope.none unless lecture

        media_in_project = Medium.where(sort: project.camelize)

        course_media_ids = media_in_project.where(teachable: lecture.course).pluck(:id)
        lecture_media_ids = media_in_project.where(teachable: lecture).pluck(:id)
        lesson_media_ids = media_in_project.where(teachable: lecture.lessons).pluck(:id)
        talk_media_ids = media_in_project.where(teachable: lecture.talks).pluck(:id)

        all_ids = (course_media_ids + lecture_media_ids + lesson_media_ids + talk_media_ids).uniq

        # Return a new scope containing only the media that matched.
        scope.where(id: all_ids)
      end
    end
  end
end
