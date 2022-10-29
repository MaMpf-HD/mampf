class RemoveNotNullConstraintFromClicker < ActiveRecord::Migration[6.0]
  def change
    change_column_null :clickers, :teachable_id, true
    change_column_null :clickers, :teachable_type, true
  end
end
