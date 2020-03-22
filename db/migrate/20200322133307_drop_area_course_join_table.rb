class DropAreaCourseJoinTable < ActiveRecord::Migration[6.0]
  def change
  	drop_table :area_course_joins
  end
end
