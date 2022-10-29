class AddCurrentLectureIdToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :current_lecture_id, :integer
  end
end
