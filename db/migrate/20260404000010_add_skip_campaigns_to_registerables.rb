class AddSkipCampaignsToRegisterables < ActiveRecord::Migration[8.0]
  def change
    # Existing tutorials and talks should not be affected by campaigns,
    # so we set skip_campaigns to true for them, then change the default
    # to false for new records.
    add_column :tutorials, :skip_campaigns, :boolean, default: true, null: false
    add_column :talks, :skip_campaigns, :boolean, default: true, null: false
    change_column_default :tutorials, :skip_campaigns, from: true, to: false
    change_column_default :talks, :skip_campaigns, from: true, to: false

    # Cohorts have no "old" records (we've just introduced them as new table
    # to the database), so we can directly set the default to false.
    add_column :cohorts, :skip_campaigns, :boolean, default: false, null: false
  end
end
