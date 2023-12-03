class AddFieldsToCourseUserJoin < ActiveRecord::Migration[5.2]
  def change
    add_column :course_user_joins, :sesam, :boolean
    add_column :course_user_joins, :keks, :boolean
    add_column :course_user_joins, :erdbeere, :boolean
    add_column :course_user_joins, :kiwi, :boolean
    add_column :course_user_joins, :reste, :boolean
  end
end
