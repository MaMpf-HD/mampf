class AddTestsInPointsTotalToLectures < ActiveRecord::Migration[8.1]
  def change
    add_column :lectures, :tests_in_points_total, :boolean, default: true, null: false
  end
end
