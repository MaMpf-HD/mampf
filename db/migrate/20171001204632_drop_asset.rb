class DropAsset < ActiveRecord::Migration[5.1]
  def change
    drop_table :assets # rubocop:todo Rails/ReversibleMigration
    drop_table :asset_medium_joins # rubocop:todo Rails/ReversibleMigration
    drop_table :connections # rubocop:todo Rails/ReversibleMigration
  end
end
