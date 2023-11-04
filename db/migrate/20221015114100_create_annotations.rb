class CreateAnnotations < ActiveRecord::Migration[7.0]
  def change
    create_table :annotations do |t|
      t.references :medium, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :timestamp, null: false
      t.text :comment
      t.string :color, null: false
      t.integer :category, null: false
      t.integer :subcategory
      t.boolean :visible_for_teacher, null: false
      t.integer :public_comment_id

      t.timestamps
    end
  end
end
