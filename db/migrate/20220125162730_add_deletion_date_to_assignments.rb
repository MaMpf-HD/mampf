class AddDeletionDateToAssignments < ActiveRecord::Migration[6.1]
  def up
    default_deletion_date = (Term.active&.end_date || (Date.today + 180.days)) + 15.days
    add_column :assignments, # rubocop:todo Rails/BulkChangeTable
               :deletion_date,
               :date, null: false, default: default_deletion_date
    remove_column :assignments, :protected, :boolean
  end

  def down
    remove_column :assignments, :deletion_date, :date # rubocop:todo Rails/BulkChangeTable
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :assignments, :protected, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
