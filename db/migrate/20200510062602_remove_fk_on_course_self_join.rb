class RemoveFkOnCourseSelfJoin < ActiveRecord::Migration[6.0]
  def change
    return unless foreign_key_exists?(:course_self_joins, :courses)

    remove_foreign_key :course_self_joins, :courses
  end
end
