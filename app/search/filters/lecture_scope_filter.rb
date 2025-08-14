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
        return scope if option.blank? || option == "0"

        case option
        when "1" then apply_subscribed_filter
        when "2" then apply_custom_filter
        else scope
        end
      end

      private

        def apply_subscribed_filter
          subscribed_lecture_ids = user.lectures.select(:id)
          subscribed_course_ids = user.lectures.select(:course_id).distinct
          subscribed_lesson_ids = Lesson.where(lecture_id: subscribed_lecture_ids).select(:id)

          scope.where(teachable_type: "Course", teachable_id: subscribed_course_ids)
               .or(scope.where(teachable_type: "Lecture", teachable_id: subscribed_lecture_ids))
               .or(scope.where(teachable_type: "Lesson", teachable_id: subscribed_lesson_ids))
        end

        def apply_custom_filter
          custom_lecture_ids = params[:media_lectures].to_a.compact_blank
          return scope if custom_lecture_ids.empty?

          lesson_ids = Lesson.where(lecture_id: custom_lecture_ids).select(:id)

          scope.where(teachable_type: "Lecture", teachable_id: custom_lecture_ids)
               .or(scope.where(teachable_type: "Lesson", teachable_id: lesson_ids))
        end
    end
  end
end
