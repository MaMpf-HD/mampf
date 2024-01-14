class AddEmergencyLinkStatusAndEmergencyLinkToLecture < ActiveRecord::Migration[7.0]
  def change
    change_table :users, bulk: true do |t|
      t.integer :emergency_link_status, default: 0, null: false
      t.text :emergency_link
    end
  end
end
