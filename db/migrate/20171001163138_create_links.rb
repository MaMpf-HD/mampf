class CreateLinks < ActiveRecord::Migration[5.1]
  def change
    create_table :links do |t|
      t.references :medium, index: true, foreign_key: true
      t.references :linked_medium, index: true

      t.timestamps null: false
    end

    add_foreign_key :links, :media, column: :linked_medium_id
    add_index :links, [:medium_id, :linked_medium_id], unique: true
  end
end
