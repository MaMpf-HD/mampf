class ChangeAnnotationsStatusDefaultInMediaAndLectures < ActiveRecord::Migration[7.0]
  def change
    change_column_default :media, :annotations_status, 0
    change_column_default :lectures, :annotations_status, -1
  end
end
