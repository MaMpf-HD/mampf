class AddTeacherIdToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :teacher_id, :integer
  end
end
