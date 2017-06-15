class CreateSesamAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :sesam_assets do |t|

      t.timestamps
    end
  end
end
