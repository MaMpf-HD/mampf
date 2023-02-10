class AddAnnotationsStatusToMedium < ActiveRecord::Migration[7.0]
  def change
    add_column :media, :annotations_status, :integer
  end
end
