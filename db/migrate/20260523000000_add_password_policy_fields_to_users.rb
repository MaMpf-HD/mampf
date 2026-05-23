class AddPasswordPolicyFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users,
               :password_policy_version,
               :integer,
               default: 0,
               null: false
    add_column :users, :password_changed_at, :datetime
  end
end
