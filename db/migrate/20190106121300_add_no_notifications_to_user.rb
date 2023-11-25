class AddNoNotificationsToUser < ActiveRecord::Migration[5.2]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :no_notifications, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
