class AddStreaksToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_activity, :datetime, default: Time.zone.now.prev_week
    add_column :users, :activity_streak, :integer, default: 0
  end
end
