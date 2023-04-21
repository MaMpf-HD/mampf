class CreateDivisionCourseJoins < ActiveRecord::Migration[6.0]
  def change
    create_table :division_course_joins do |t|
      t.references :division, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
