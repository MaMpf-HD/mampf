class RemoveLinkFromReferral < ActiveRecord::Migration[5.2]
  def change
    remove_column :referrals, :link, :boolean
  end
end
