# rubocop:disable Rails/
class AddMediumLinkToReferral < ActiveRecord::Migration[5.2]
  def change
    add_column :referrals, :medium_link, :boolean
  end
end
# rubocop:enable Rails/
