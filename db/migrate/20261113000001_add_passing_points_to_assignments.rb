class AddPassingPointsToAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :assignments, :passing_points, :decimal, precision: 10, scale: 2
    add_check_constraint :assignments, "passing_points > 0",
                         name: "passing_points_positive"
    add_check_constraint :assignments, "kind = 1 OR passing_points IS NULL",
                         name: "passing_points_only_for_tests"
  end
end
