class RemoveTeacherFromLecture < ActiveRecord::Migration[5.1]
  def change
    remove_column :lectures, :teacher, :string
  end
end
