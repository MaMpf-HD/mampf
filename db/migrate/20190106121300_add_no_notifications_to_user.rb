class AddNoNotificationsToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :no_notifications, :boolean, default: false
  end
end
