class RemoveEmailNotificationsFromUser < ActiveRecord::Migration[6.0]
  def change

    remove_column :users, :email_notifications, :boolean
  end
end
