class AddSkipCampaignsToRegisterables < ActiveRecord::Migration[8.0]
  def change
    add_column :tutorials, :skip_campaigns, :boolean, default: false, null: false
    add_column :talks, :skip_campaigns, :boolean, default: false, null: false
    add_column :cohorts, :skip_campaigns, :boolean, default: false, null: false
  end
end
