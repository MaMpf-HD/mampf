class CreateCourseSelfJoin < ActiveRecord::Migration[5.2]
  def change
    create_table :course_self_joins do |t|
      t.references :course, index: true, foreign_key: true
      t.references :preceding_course, index: true

      t.timestamps null: false
    end

    add_foreign_key :course_self_joins, :courses, column: :preceding_course_id
    add_index :course_self_joins, [:course_id, :preceding_course_id], unique: true
  end
end
