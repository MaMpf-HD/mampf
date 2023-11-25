class AddFieldsToCourseUserJoin < ActiveRecord::Migration[5.2]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :course_user_joins, :sesam, :boolean # rubocop:todo Rails/BulkChangeTable, Rails/ThreeStateBooleanColumn
    # rubocop:enable Rails/ThreeStateBooleanColumn
    add_column :course_user_joins, :keks, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :course_user_joins, :erdbeere, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :course_user_joins, :kiwi, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :course_user_joins, :reste, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
