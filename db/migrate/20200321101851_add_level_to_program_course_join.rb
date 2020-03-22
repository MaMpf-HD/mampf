class AddLevelToProgramCourseJoin < ActiveRecord::Migration[6.0]
  def change
    add_column :program_course_joins, :level, :integer
  end
end
