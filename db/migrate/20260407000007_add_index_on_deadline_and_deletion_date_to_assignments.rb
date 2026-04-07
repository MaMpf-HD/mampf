class AddIndexOnDeadlineAndDeletionDateToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_index :assignments, [:deadline, :deletion_date],
              name: "index_assignments_on_deadline_and_deletion_date"
  end
end
