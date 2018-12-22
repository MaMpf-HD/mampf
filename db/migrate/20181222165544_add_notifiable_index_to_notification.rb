class AddNotifiableIndexToNotification < ActiveRecord::Migration[5.2]
  def change
  	add_index :notifications, [:notifiable_id, :notifiable_type]
  end
end
