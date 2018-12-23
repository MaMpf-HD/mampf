class RemoveNewsFromCourseUserJoin < ActiveRecord::Migration[5.2]
  def change
    remove_column :course_user_joins, :news?, :boolean
  end
end
