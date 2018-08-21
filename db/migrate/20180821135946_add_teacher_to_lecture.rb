class AddTeacherToLecture < ActiveRecord::Migration[5.2]
  def change
    add_reference :lectures, :user, foreign_key: true
  end
end
