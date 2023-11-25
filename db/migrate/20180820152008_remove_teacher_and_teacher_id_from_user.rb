class RemoveTeacherAndTeacherIdFromUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :teacher, :boolean # rubocop:todo Rails/BulkChangeTable
    remove_column :users, :teacher_id, :integer
  end
end
