class AddIndexToNotification < ActiveRecord::Migration[5.2]
  def change
  	add_index :notifications, :recipient_id
  end
end
