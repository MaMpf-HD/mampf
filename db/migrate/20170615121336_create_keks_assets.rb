class CreateKeksAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :keks_assets do |t|

      t.timestamps
    end
  end
end
