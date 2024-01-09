class AddEmergencyLinkStatusAndEmergencyLinkToLecture < ActiveRecord::Migration[7.0]
  def change
    # rubocop:todo Rails/BulkChangeTable
    add_column :lectures, :emergency_link_status, :integer, default: 0
    # rubocop:enable Rails/BulkChangeTable
    add_column :lectures, :emergency_link, :text
  end
end
