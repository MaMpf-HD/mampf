class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.integer :recipient_id
      t.integer :notifiable_id
      t.text :notifiable_type
      t.text :action

      t.timestamps
    end
  end
end
