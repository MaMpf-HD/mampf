class AddExcludedAtToExamRosters < ActiveRecord::Migration[8.0]
  def change
    add_column :exam_rosters, :excluded_at, :datetime
    add_index :exam_rosters, [:exam_id, :excluded_at]
  end
end
