class CreateAssetMedia < ActiveRecord::Migration[5.1]
  def change
    create_table :asset_media do |t|
      t.references :learning_asset, foreign_key: true
      t.references :medium, foreign_key: true

      t.timestamps
    end
  end
end
