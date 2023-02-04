class AddAnnotationsStatusToLecture < ActiveRecord::Migration[6.1]
  def change
    add_column :lectures, :annotations_status, :integer
  end
end
