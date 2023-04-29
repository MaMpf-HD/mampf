class CreateAnnotations < ActiveRecord::Migration[7.0]
  def change
    create_table :annotations do |t|
      t.references :medium, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :timestamp, null: false
      t.text :comment
      t.integer :category
      t.boolean :visible_for_teacher
      t.string :color

      t.timestamps
    end
  end
end
