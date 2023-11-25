class AddNewsToCourseUserJoin < ActiveRecord::Migration[5.2]
  def change
    add_column :course_user_joins, :news, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
