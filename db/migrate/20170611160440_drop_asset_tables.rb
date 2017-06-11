class DropAssetTables < ActiveRecord::Migration[5.1]
  def change
    drop_table :learning_assets
    drop_table :learning_media
  end
end
