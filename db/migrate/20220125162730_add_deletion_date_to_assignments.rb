class AddDeletionDateToAssignments < ActiveRecord::Migration[6.1]
  def up
    add_column :assignments,
               :deletion_date,
               :date, null: false, default: (Term.active&.end_date || (Date.today + 180.days)) + 15.days
    remove_column :assignments, :protected, :boolean
  end

  def down
    remove_column :assignments, :deletion_date, :date
    add_column :assignments, :protected, :boolean, default: false
  end
end
