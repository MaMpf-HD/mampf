class AddConsentsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :consents, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
