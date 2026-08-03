class SetPerformanceRecordAchievementIdsNotNull < ActiveRecord::Migration[8.0]
  COLUMNS = [:achievements_met_ids, :achievements_ungraded_ids].freeze

  def up
    COLUMNS.each do |column|
      # rubocop:disable Rails/SkipsModelValidations
      StudentPerformance::Record.where(column => nil).update_all(column => [])
      # rubocop:enable Rails/SkipsModelValidations
      change_column_null :student_performance_records, column, false
    end
  end

  def down
    COLUMNS.each do |column|
      change_column_null :student_performance_records, column, true
    end
  end
end
