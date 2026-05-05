class CreateExams < ActiveRecord::Migration[8.0]
  def change
    create_table :exams do |t|
      t.bigint :lecture_id, null: false
      t.string :title, null: false
      t.datetime :date
      t.text :location
      t.integer :capacity
      t.text :description

      t.timestamps
    end

    add_index :exams, :lecture_id
    add_index :exams, [:lecture_id, :date]

    add_foreign_key :exams, :lectures
  end
end