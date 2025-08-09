# Establishes the initial scope of media for a lecture's index page.
#
# This filter finds all media for a given "project" (a Medium sort) that are
# associated with the given lecture, its lessons, or its parent course.
module Search
  module Filters
    class LectureMediaScopeFilter < BaseFilter
      def call
        lecture_id = params[:id]
        project = params[:project]

        return scope.none unless lecture_id && project.present?

        # This is a more efficient way to get the course_id without loading
        # the entire lecture object.
        course_id = Lecture.where(id: lecture_id).pick(:course_id)
        return scope.none unless course_id

        # Define subqueries for lesson and talk IDs. This keeps the logic in the DB.
        lesson_ids = Lesson.where(lecture_id: lecture_id).select(:id)
        talk_ids = Talk.where(lecture_id: lecture_id).select(:id)

        # First, build the query to find all media associated with the lecture's
        # hierarchy (Course, Lecture, Lesson, Talk).
        media_in_hierarchy = scope
                             .where(teachable_type: "Course", teachable_id: course_id)
                             .or(scope.where(teachable_type: "Lecture", teachable_id: lecture_id))
                             .or(scope.where(teachable_type: "Lesson", teachable_id: lesson_ids))
                             .or(scope.where(teachable_type: "Talk", teachable_id: talk_ids))

        # Then, apply the project/sort filter to the *entire* result of that query.
        # This ensures the sort is applied to all parts of the OR condition.
        media_in_hierarchy.where(sort: project.camelize)
      end
    end
  end
end
