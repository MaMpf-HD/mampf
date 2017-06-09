class AddTeacherIdToLecture < ActiveRecord::Migration[5.1]
  def change
    add_column :lectures, :teacher_id, :integer
  end
end
