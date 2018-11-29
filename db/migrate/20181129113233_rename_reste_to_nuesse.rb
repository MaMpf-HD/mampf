class RenameResteToNuesse < ActiveRecord::Migration[5.2]
  def change
    rename_column :course_user_joins, :reste?, :nuesse?
  end
end