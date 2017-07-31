class RenameCourseContentsToCoursesTags < ActiveRecord::Migration[5.1]
  def change
    rename_table :course_contents, :courses_tags
  end
end
