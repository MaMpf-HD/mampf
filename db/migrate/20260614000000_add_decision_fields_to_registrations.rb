class AddDecisionFieldsToRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_column :registration_campaigns, :allocation_decided_at, :datetime

    change_table :registration_user_registrations, bulk: true do |t|
      t.string :rejection_reason_type
      t.string :rejection_reason_code
      t.string :rejection_reason_label
      t.datetime :rejected_at
    end
  end
end
