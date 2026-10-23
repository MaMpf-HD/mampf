# Marks the few people in the dean's office who read every lecture's groups,
# seats and registrations, without the rights of an admin.
class AddDeansOfficeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :deans_office, :boolean, default: false, null: false
  end
end
