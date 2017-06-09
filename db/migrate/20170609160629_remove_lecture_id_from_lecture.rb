class RemoveLectureIdFromLecture < ActiveRecord::Migration[5.1]
  def change
    remove_column :lectures, :lecture_id, :integer
  end
end
