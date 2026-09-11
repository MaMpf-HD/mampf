class AddFinalizedAtToRegistrationCampaigns < ActiveRecord::Migration[8.0]
  def change
    add_column :registration_campaigns, :finalized_at, :datetime
  end
end
