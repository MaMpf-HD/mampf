# rubocop:disable Rails/
class RemoveTeacherFragments < ActiveRecord::Migration[5.2]
  def change
    remove_column :lectures, :teacher_id
    remove_reference :users, :teacher, foreign_key: true, index: true
  end
end
# rubocop:enable Rails/
