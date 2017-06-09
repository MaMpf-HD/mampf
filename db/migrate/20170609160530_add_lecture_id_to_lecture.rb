class AddLectureIdToLecture < ActiveRecord::Migration[5.1]
  def change
    add_column :lectures, :lecture_id, :integer
  end
end
