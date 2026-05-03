class AddExcludedAtToExamRosterEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :exam_roster_entries, :excluded_at, :datetime
    add_index :exam_roster_entries, [:exam_id, :excluded_at]
  end
end