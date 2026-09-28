# Marks the people who correct what users cannot change themselves once it
# is saved: their name and matriculation number.
class AddSupportToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :support, :boolean, default: false, null: false
  end
end
