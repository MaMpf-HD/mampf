class AddTestsPassedToStudentPerformance < ActiveRecord::Migration[8.1]
  def change
    add_column :student_performance_rules, :min_tests_passed, :integer
    add_check_constraint :student_performance_rules, "min_tests_passed > 0",
                         name: "min_tests_passed_positive"

    add_column :student_performance_records, :tests_passed_ids, :jsonb,
               default: [], null: false
    add_column :student_performance_records, :tests_failed_ids, :jsonb,
               default: [], null: false
  end
end
