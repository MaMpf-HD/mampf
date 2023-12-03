# rubocop:disable Rails/
class AddTeacherToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :teacher, :boolean
  end
end
# rubocop:enable Rails/
