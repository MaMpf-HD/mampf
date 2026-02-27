class AddAssessmentCountsToPerformanceRecords < ActiveRecord::Migration[8.0]
  def change
    change_table :student_performance_records, bulk: true do |t|
      t.integer :assessments_total_count, default: 0, null: false
      t.integer :assessments_reviewed_count, default: 0, null: false
      t.integer :assessments_pending_grading_count, default: 0, null: false
      t.integer :assessments_not_submitted_count, default: 0, null: false
      t.integer :assessments_exempt_count, default: 0, null: false
    end
  end
end
