class CreateStudentPerformanceRules < ActiveRecord::Migration[8.0]
  def change
    create_table :student_performance_rules, id: :uuid do |t|
      t.bigint :lecture_id, null: false
      t.decimal :min_percentage, precision: 5, scale: 2
      t.decimal :min_points_absolute, precision: 10, scale: 2
      t.boolean :active, default: false, null: false

      t.timestamps
    end

    add_index :student_performance_rules, :lecture_id
    add_foreign_key :student_performance_rules, :lectures
  end
end
