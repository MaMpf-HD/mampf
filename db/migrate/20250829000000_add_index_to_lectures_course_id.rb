class AddIndexToLecturesCourseId < ActiveRecord::Migration[8.0]
  def change
    add_index :lectures, :course_id
  end
end
