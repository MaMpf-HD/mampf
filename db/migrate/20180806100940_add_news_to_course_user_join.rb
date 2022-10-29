class AddNewsToCourseUserJoin < ActiveRecord::Migration[5.2]
  def change
    add_column :course_user_joins, :news, :boolean
  end
end
