class CreateCourseUserJoins < ActiveRecord::Migration[5.2]
  def change
    create_table :course_user_joins do |t|
      t.references :course, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
