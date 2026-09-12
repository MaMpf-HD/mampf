class RemovePointsMaxPendingFromStudentPerformanceRecords < ActiveRecord::Migration[8.0]
  def change
    remove_column :student_performance_records, :points_max_pending_materialized,
                  :decimal, precision: 10, scale: 2
  end
end
