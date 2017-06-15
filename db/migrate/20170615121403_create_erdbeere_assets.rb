class CreateErdbeereAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :erdbeere_assets do |t|

      t.timestamps
    end
  end
end
