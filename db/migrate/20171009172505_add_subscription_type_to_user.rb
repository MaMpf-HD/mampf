class AddSubscriptionTypeToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :subscription_type, :integer
  end
end
