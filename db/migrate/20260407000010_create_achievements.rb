class CreateAchievements < ActiveRecord::Migration[8.0]
  def change
    create_table :achievements do |t|
      t.bigint :lecture_id, null: false
      t.string :title, null: false
      t.integer :value_type, default: 0, null: false
      t.decimal :threshold, precision: 10, scale: 2
      t.text :description

      t.timestamps
    end

    add_index :achievements, :lecture_id
    add_foreign_key :achievements, :lectures
  end
end
