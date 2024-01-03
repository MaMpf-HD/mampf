# rubocop:disable Rails/
class DropAsset < ActiveRecord::Migration[5.1]
  def change
    drop_table :assets
    drop_table :asset_medium_joins
    drop_table :connections
  end
end
# rubocop:enable Rails/
