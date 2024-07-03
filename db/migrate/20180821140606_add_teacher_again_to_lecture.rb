class AddTeacherAgainToLecture < ActiveRecord::Migration[5.2]
  def change
    #    add_reference :lectures, :teacher, foreign_key: true
    add_column :lectures, :teacher_id, :integer
    add_index :lectures, :teacher_id
  end
end
