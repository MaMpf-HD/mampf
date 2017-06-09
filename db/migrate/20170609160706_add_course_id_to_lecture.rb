class AddCourseIdToLecture < ActiveRecord::Migration[5.1]
  def change
    add_column :lectures, :course_id, :integer
  end
end
