# Filters a scope of lectures to only include records that are visible to the
# current user.
#
# This filter ensures that non-admin users can only see lectures that meet
# at least one of the following criteria:
# - The lecture is published (i.e., its `released` status is not nil).
# - The user is the teacher of the lecture.
# - The user is an editor of the lecture.
#
# If the user is an admin, the scope is returned unmodified, granting them
# access to all lectures.
module Search
  module Filters
    class LectureVisibilityFilter < BaseFilter
      def filter
        return scope if user&.admin?

        # A left_outer_join is necessary because a lecture might not have an
        # editor, but we still need to check the other conditions.
        #
        # This query is safe from SQL injection because it uses parameterized
        # queries (the `:user_id` placeholder) instead of string interpolation.#
        scope.left_outer_joins(:editable_user_joins)
             .where(
               "lectures.released IS NOT NULL OR " \
               "lectures.teacher_id = :user_id OR " \
               "editable_user_joins.user_id = :user_id",
               user_id: user.id
             )
      end
    end
  end
end
