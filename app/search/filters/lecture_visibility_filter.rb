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
      def call
        return scope if user&.admin?

        # Get a reference to the base scope to build the .or clauses
        lectures = Lecture.arel_table
        joins = EditableUserJoin.arel_table

        # Define the three separate conditions for visibility
        is_published = lectures[:released].not_eq(nil)
        is_teacher = lectures[:teacher_id].eq(user.id)
        is_editor = joins[:user_id].eq(user.id)

        # Chain the conditions together using .or()
        scope.left_outer_joins(:editable_user_joins)
             .where(is_published.or(is_teacher).or(is_editor))
      end
    end
  end
end
