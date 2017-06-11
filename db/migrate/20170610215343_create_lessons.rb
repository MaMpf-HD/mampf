class CreateLessons < ActiveRecord::Migration[5.1]
  def change
    create_table :lessons do |t|
      t.integer :number
      t.date :date
      t.references :lecture, foreign_key: true

      t.timestamps
    end
  end
end
