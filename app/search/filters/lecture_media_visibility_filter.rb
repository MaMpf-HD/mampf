# Applies the special visibility rules for a lecture's media index page.
#
# This filter replicates the logic based on the `params[:visibility]` value
# ('lecture' or 'thematic') from the legacy search implementation.
module Search
  module Filters
    class LectureMediaVisibilityFilter < BaseFilter
      def call
        lecture_id = params[:id]
        visibility = params[:visibility]

        return scope if visibility.blank? || visibility == "all" || lecture_id.blank?

        lecture = Lecture.find_by(id: lecture_id)
        return scope unless lecture

        case visibility
        when "lecture"
          scope.where.not(teachable_type: "Course")
        when "thematic"
          return scope if user.admin? || lecture.edited_by?(user)

          # For regular users, keep media that are either:
          # 1. Not associated with a Course.
          # 2. Associated with the Course AND have tags that intersect with the
          #    lecture's tags.
          lecture_tags = lecture.tags_including_media_tags

          # Condition 1: Media that are not associated with a Course.
          non_course_media = scope.where.not(teachable_type: "Course")

          # Condition 2: Media that ARE associated with the lecture's course
          # AND have tags that intersect with the lecture's tags.
          # To avoid a "structurally incompatible" error with .or(), we use a
          # subquery to find the IDs of course media that have the correct tags.
          # This avoids a top-level JOIN in one branch of the OR condition.
          course_media_with_tags_ids = scope.where(teachable: lecture.course)
                                            .joins(:tags)
                                            .where(tags: { id: lecture_tags })
                                            .select(:id)

          # Now we can build the OR query. Both sides are simple WHERE clauses
          # on the media table, making them structurally compatible.
          non_course_media.or(scope.where(id: course_media_with_tags_ids))
        else
          scope
        end
      end
    end
  end
end
