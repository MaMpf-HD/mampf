class CreateRelations < ActiveRecord::Migration[5.1]
  def change
    create_table :relations do |t|
      t.references :tag, index: true, foreign_key: true
      t.references :related_tag, index: true

      t.timestamps null: false
    end

    add_foreign_key :relations, :tags, column: :related_tag_id
    add_index :relations, [:tag_id, :related_tag_id], unique: true
  end
end
