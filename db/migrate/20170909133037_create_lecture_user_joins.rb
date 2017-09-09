class CreateLectureUserJoins < ActiveRecord::Migration[5.1]
  def change
    create_table :lecture_user_joins do |t|
      t.references :lecture, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
