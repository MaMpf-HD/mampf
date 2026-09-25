class AddDismissedAtToRegistrationUserRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_column :registration_user_registrations, :dismissed_at, :datetime
  end
end
