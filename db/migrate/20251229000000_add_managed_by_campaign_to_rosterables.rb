class AddManagedByCampaignToRosterables < ActiveRecord::Migration[8.0]
  def change
    add_column :tutorials, :managed_by_campaign, :boolean, default: true, null: false
    add_column :talks, :managed_by_campaign, :boolean, default: true, null: false
    add_column :lectures, :managed_by_campaign, :boolean, default: true, null: false
  end
end
