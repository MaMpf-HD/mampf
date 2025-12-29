class AddCampaignableToRosterables < ActiveRecord::Migration[8.0]
  def change
    add_column :tutorials, :campaignable, :boolean, default: true, null: false
    add_column :talks, :campaignable, :boolean, default: true, null: false
    add_column :lectures, :campaignable, :boolean, default: true, null: false
  end
end
