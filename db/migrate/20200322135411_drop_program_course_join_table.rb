class DropProgramCourseJoinTable < ActiveRecord::Migration[6.0]
  def change
  	drop_table :program_course_joins
  end
end
