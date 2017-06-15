class CreateResteAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :reste_assets do |t|

      t.timestamps
    end
  end
end
