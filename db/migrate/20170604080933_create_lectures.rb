class CreateLectures < ActiveRecord::Migration[5.1]
  def change
    create_table :lectures do |t|
      t.string :term
      t.string :teacher
      t.string :course_id

      t.timestamps
    end
  end
end
