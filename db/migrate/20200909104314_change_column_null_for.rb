class ChangeColumnNullFor < ActiveRecord::Migration[6.0]
  def change
    change_column_null :tutorials, :tutor_id, true
  end
end
