class AddProtectedToAssignment < ActiveRecord::Migration[6.1]
  def change
    add_column :assignments, :protected, :boolean, :default => false
  end
end
