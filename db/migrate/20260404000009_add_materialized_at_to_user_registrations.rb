class AddMaterializedAtToUserRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_column :registration_user_registrations, :materialized_at, :datetime
  end
end
