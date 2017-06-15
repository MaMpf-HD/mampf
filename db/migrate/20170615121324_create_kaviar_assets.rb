class CreateKaviarAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :kaviar_assets do |t|

      t.timestamps
    end
  end
end
