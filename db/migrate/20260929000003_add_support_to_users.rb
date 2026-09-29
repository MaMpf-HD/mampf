class AddSupportToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :support, :boolean, default: false, null: false
  end
end
