class CreateAnnotations < ActiveRecord::Migration[6.1]
  def change
    create_table :annotations do |t|
      t.references :medium, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :timestamp
      t.string :color

      t.timestamps
    end
  end
end
