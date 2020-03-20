class CreateProgramCourseJoins < ActiveRecord::Migration[6.0]
  def change
    create_table :program_course_joins do |t|
      t.references :program, foreign_key: true
      t.references :course, foreign_key: true

      t.timestamps
    end
  end
end
