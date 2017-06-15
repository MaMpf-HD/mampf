class CreateAssetTags < ActiveRecord::Migration[5.1]
  def change
    create_table :asset_tags do |t|
      t.references :learning_asset, foreign_key: true
      t.references :tag, foreign_key: true

      t.timestamps
    end
  end
end
