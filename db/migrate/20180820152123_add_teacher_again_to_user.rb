class AddTeacherAgainToUser < ActiveRecord::Migration[5.2]
  def change
    add_reference :users, :teacher, foreign_key: true, index: true
  end
end
