# Applies the special visibility rules for a lecture's media index page.
#
# This filter replicates the logic based on the `params[:visibility]` value
# ('lecture' or 'thematic') from the legacy search implementation.
module Search
  module Filters
    class LectureMediaVisibilityFilter < BaseFilter
      def call
        lecture_id = params[:_id]
        visibility = params[:visibility]

        # Default behavior if no visibility is set, or if it's 'all'.
        return scope if visibility.blank? || visibility == "all" || lecture_id.blank?

        lecture = Lecture.find_by(id: lecture_id)
        return scope unless lecture

        case visibility
        when "lecture"
          # Reject media whose teachable is a Course.
          scope.where.not(teachable_type: "Course")
        when "thematic"
          # For admins/editors, show everything.
          return scope if user.admin? || lecture.edited_by?(user)

          # For regular users, keep media that are either:
          # 1. Not associated with a Course.
          # 2. Associated with the Course AND have tags that intersect with the
          #    lecture's tags.
          lecture_tags = lecture.tags_including_media_tags
          course_media_with_tags_ids = scope.where(teachable: lecture.course)
                                            .joins(:tags)
                                            .where(tags: { id: lecture_tags })
                                            .pluck(:id)
          non_course_media_ids = scope.where.not(teachable_type: "Course").pluck(:id)

          scope.where(id: course_media_with_tags_ids + non_course_media_ids)
        else
          scope
        end
      end
    end
  end
end
