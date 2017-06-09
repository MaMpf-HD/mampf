class RemoveFalseCourseIdFromLecture < ActiveRecord::Migration[5.1]
  def change
    remove_column :lectures, :course_id, :string
  end
end
