class CreateConnections < ActiveRecord::Migration[5.1]
  def change
    create_table :connections do |t|
      t.references :learning_asset, index: true, foreign_key: true
      t.references :linked_asset, index: true

      t.timestamps null: false
    end

    add_foreign_key :connections, :learning_assets, column: :linked_asset_id
    add_index :connections, [:learning_asset_id, :linked_asset_id],
                            unique: true
  end
end
