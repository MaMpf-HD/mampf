class AddEmergencyLinkStatusAndEmergencyLinkToLecture < ActiveRecord::Migration[7.0]
  def change
    add_column :lectures, :emergency_link_status, :integer, default: 0
    add_column :lectures, :emergency_link, :text
  end
end
