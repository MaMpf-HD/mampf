class AddLevelToAreaCourseJoin < ActiveRecord::Migration[6.0]
  def change
    add_column :area_course_joins, :level, :integer
  end
end
