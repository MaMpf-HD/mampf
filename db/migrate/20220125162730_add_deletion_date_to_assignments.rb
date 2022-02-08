class AddDeletionDateToAssignments < ActiveRecord::Migration[6.1]
  def change
    add_column :assignments,
               :deletion_date,
               :datetime, null: false, default: (Term.active&.end_date || (Date.today + 180.days)) + 15.days
    remove_column :assignments, :protected, :boolean, :default => false
  end
end
