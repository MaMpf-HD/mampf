class AddAnnotationsStatusToMedium < ActiveRecord::Migration[6.1]
  def change
    add_column :media, :annotations_status, :integer
  end
end
