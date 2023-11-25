class AddAdminToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :admin, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
