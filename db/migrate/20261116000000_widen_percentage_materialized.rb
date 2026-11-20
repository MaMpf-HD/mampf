class WidenPercentageMaterialized < ActiveRecord::Migration[8.1]
  def up
    change_column :student_performance_records, :percentage_materialized, :decimal
  end

  def down
    change_column :student_performance_records, :percentage_materialized, :decimal,
                  precision: 5, scale: 2
  end
end
