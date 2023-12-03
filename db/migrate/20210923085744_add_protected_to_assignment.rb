class AddProtectedToAssignment < ActiveRecord::Migration[6.1]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :assignments, :protected, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
