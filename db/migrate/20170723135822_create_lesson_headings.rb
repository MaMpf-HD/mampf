class CreateLessonHeadings < ActiveRecord::Migration[5.1]
  def change
    create_table :lesson_headings do |t|
      t.references :lesson, foreign_key: true
      t.references :section, foreign_key: true

      t.timestamps
    end
  end
end
