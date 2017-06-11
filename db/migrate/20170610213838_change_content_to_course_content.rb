class ChangeContentToCourseContent < ActiveRecord::Migration[5.1]
  def change
    rename_table :contents, :course_contents
  end
end
