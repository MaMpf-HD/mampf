class WidenPercentageMaterialized < ActiveRecord::Migration[8.1]
  def up
    change_column :student_performance_records, :percentage_materialized, :decimal
  end

  # The column stays wide: it also holds what the code before this migration
  # writes, and narrowing it would fail on a percentage of 1000 or more.
  def down
  end
end
