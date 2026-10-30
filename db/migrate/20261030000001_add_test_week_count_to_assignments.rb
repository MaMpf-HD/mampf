class AddTestWeekCountToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :assignments, :test_week_count, :integer, default: 1, null: false
    add_check_constraint :assignments, "test_week_count >= 1",
                         name: "test_week_count_positive"
  end
end
