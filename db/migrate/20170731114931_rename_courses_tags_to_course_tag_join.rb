class RenameCoursesTagsToCourseTagJoin < ActiveRecord::Migration[5.1]
  def change
    rename_table :courses_tags, :course_tag_joins
  end
end
