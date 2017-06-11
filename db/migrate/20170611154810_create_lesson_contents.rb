class CreateLessonContents < ActiveRecord::Migration[5.1]
  def change
    create_table :lesson_contents do |t|
      t.references :lesson, foreign_key: true
      t.references :tag, foreign_key: true

      t.timestamps
    end
  end
end
