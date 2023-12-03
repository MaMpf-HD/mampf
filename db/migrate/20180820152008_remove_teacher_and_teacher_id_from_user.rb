# rubocop:disable Rails/
class RemoveTeacherAndTeacherIdFromUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :teacher, :boolean
    remove_column :users, :teacher_id, :integer
  end
end
# rubocop:enable Rails/
