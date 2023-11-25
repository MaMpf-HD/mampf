class AddMediumLinkToReferral < ActiveRecord::Migration[5.2]
  def change
    add_column :referrals, :medium_link, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
