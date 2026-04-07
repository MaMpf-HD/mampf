class RenameTitleToDescriptionInRegistrationCampaigns < ActiveRecord::Migration[8.0]
  def change
    rename_column :registration_campaigns, :title, :description
    change_column_null :registration_campaigns, :description, true
  end
end
