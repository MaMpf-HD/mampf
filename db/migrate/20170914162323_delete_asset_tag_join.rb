class DeleteAssetTagJoin < ActiveRecord::Migration[5.1]
  def change
    drop_table :asset_tag_joins # rubocop:todo Rails/ReversibleMigration
  end
end
