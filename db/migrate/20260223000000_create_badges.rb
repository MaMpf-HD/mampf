class CreateBadges < ActiveRecord::Migration[8.0]
  def change
    create_table :badges do |t|
      t.string :title, null: false, unique: true
      t.text :description, null: false
      t.string :icon_key, null: false
      t.timestamps
    end

    # This might be redundant as they are hardcoded anyways
    t.add_index :title, unique: true
  end
end
