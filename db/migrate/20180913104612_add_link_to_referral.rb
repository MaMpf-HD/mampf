class AddLinkToReferral < ActiveRecord::Migration[5.2]
  def change
    add_column :referrals, :link, :boolean
  end
end
