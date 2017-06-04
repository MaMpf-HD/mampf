class RemoveTeacherIdFromLecture < ActiveRecord::Migration[5.1]
  def change
    remove_column :lectures, :teacher_id, :integer
  end
end
