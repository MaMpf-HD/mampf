class AddAchievementsUngradedIdsToStudentPerformanceRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :student_performance_records, :achievements_ungraded_ids,
               :jsonb, default: []
  end
end
