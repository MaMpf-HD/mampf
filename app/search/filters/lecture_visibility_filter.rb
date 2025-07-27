module Filters
  class LectureVisibilityFilter < BaseFilter
    def call
      user = User.find_by(id: params[:user_id])
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
