class ChangeDeletionDateDefaultInAssignemnts < ActiveRecord::Migration[7.0]
  def change
    change_column_default(:assignments, :deletion_date,
                          from: "2020-10-15",
                          to: "2200-01-01")
  end
end
