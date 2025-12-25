class AddLastAllocationCalculatedAtToRegistrationCampaigns < ActiveRecord::Migration[7.0]
  def change
    add_column :registration_campaigns, :last_allocation_calculated_at, :datetime
  end
end
