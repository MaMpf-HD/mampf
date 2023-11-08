class AddAnnotationsStatusToLecture < ActiveRecord::Migration[7.0]
  def change
    add_column :lectures, :annotations_status, :integer, default: -1, null: false
  end
end
