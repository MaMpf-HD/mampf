class CreateAreaCourseJoins < ActiveRecord::Migration[6.0]
  def change
    create_table :area_course_joins do |t|
      t.references :area, foreign_key: true
      t.references :course, foreign_key: true

      t.timestamps
    end
  end
end
