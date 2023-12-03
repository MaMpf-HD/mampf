class RemoveBooleansFromReferral < ActiveRecord::Migration[5.2]
  def change
    remove_column :referrals, :video, :boolean
    remove_column :referrals, :manuscript, :boolean
    remove_column :referrals, :medium_link, :boolean
  end
end
