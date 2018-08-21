class AddTeacherAgainToLecture < ActiveRecord::Migration[5.2]
  def change
    add_reference :lectures, :teacher, foreign_key: true
  end
end
