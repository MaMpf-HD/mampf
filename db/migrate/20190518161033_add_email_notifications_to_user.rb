# rubocop:disable Rails/
class AddEmailNotificationsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :email_notifications, :boolean
  end
end
# rubocop:enable Rails/
