class AddTeacherToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :teacher, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
