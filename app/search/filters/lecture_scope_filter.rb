# Filters media based on their association with lectures, offering different
# scopes like 'subscribed' or 'custom'.
#
# This filter modifies the scope based on the `lecture_scope` parameter:
# - '0' or blank: The scope is returned unmodified.
# - '1': Filters for media whose teachable parent (Course, Lecture,
#   or Lesson) is one the user is subscribed to.
# - '2': Filters for media whose teachable parent is one of a specific
#   list of lectures (or their lessons) provided in the `media_lectures` param.
module Search
  module Filters
    class LectureScopeFilter < BaseFilter
      def call
        option = params[:lecture_scope]
        # '0' is for 'all', which is the default and requires no filtering.
        return scope if option.blank? || option == "0"

        case option
        when "1" # subscribed
          apply_subscribed_filter
        when "2" # custom
          apply_custom_filter
        else
          scope
        end
      end

      private

        def apply_subscribed_filter
          ids = subscribed_teachable_ids
          media = Medium.arel_table

          # Build the query conditions using Arel
          course_cond = media[:teachable_type].eq("Course")
                                              .and(media[:teachable_id].in(ids[:course_ids]))
          lecture_cond = media[:teachable_type].eq("Lecture")
                                               .and(media[:teachable_id].in(ids[:lecture_ids]))
          lesson_cond = media[:teachable_type].eq("Lesson")
                                              .and(media[:teachable_id].in(ids[:lesson_ids]))

          # Filter media that are teachable by any of these courses, lectures, or lessons.
          scope.where(course_cond.or(lecture_cond).or(lesson_cond))
        end

        def apply_custom_filter
          custom_lecture_ids = params[:media_lectures]
          return scope if custom_lecture_ids.blank?

          # Find all lessons that belong to the selected lectures.
          lesson_ids = Lesson.where(lecture_id: custom_lecture_ids).pluck(:id)
          media = Medium.arel_table

          # Build the query conditions using Arel.
          lecture_cond = media[:teachable_type].eq("Lecture")
                                               .and(media[:teachable_id].in(custom_lecture_ids))
          lesson_cond = media[:teachable_type].eq("Lesson")
                                              .and(media[:teachable_id].in(lesson_ids))

          # Filter media that are teachable by any of these lectures or lessons.
          scope.where(lecture_cond.or(lesson_cond))
        end

        # Gathers all teachable IDs related to the user's subscriptions.
        def subscribed_teachable_ids
          # Get the user's subscribed lectures.
          subscribed_lectures = user.lectures
          lecture_ids = subscribed_lectures.pluck(:id)

          {
            # Get the unique IDs of the courses these lectures belong to.
            course_ids: subscribed_lectures.pluck(:course_id).uniq,
            # Get the IDs of these lectures.
            lecture_ids: lecture_ids,
            # Find all lessons that belong to the subscribed lectures.
            lesson_ids: Lesson.where(lecture_id: lecture_ids).pluck(:id)
          }
        end
    end
  end
end
