class RemoveActivityNotification < ActiveRecord::Migration[5.2]
  def change
    drop_table :notifications
    drop_table :subscriptions
  end
end
