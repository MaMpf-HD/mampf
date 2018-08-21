class RemoveUserTeacherFromLecture < ActiveRecord::Migration[5.2]
  def change
    remove_reference :lectures, :user, foreign_key: true
  end
end
