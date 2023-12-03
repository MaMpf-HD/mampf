class AddDeletionDateToAssignments < ActiveRecord::Migration[6.1]
  def up
    add_column :assignments, # rubocop:todo Rails/BulkChangeTable
               :deletion_date,
               # rubocop:todo Layout/LineLength
               :date, null: false, default: (Term.active&.end_date || (Date.today + 180.days)) + 15.days
    # rubocop:enable Layout/LineLength
    remove_column :assignments, :protected, :boolean
  end

  def down
    remove_column :assignments, :deletion_date, :date # rubocop:todo Rails/BulkChangeTable
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :assignments, :protected, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
