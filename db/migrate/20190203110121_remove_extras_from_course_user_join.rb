class RemoveExtrasFromCourseUserJoin < ActiveRecord::Migration[5.2]
  def change
    remove_column :course_user_joins, :sesam?, :boolean # rubocop:todo Rails/BulkChangeTable
    remove_column :course_user_joins, :keks?, :boolean
    remove_column :course_user_joins, :erdbeere?, :boolean
    remove_column :course_user_joins, :kiwi?, :boolean
    remove_column :course_user_joins, :nuesse?, :boolean
  end
end
