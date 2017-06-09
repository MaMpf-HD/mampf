class RemoveTimeStampFromExternalReference < ActiveRecord::Migration[5.1]
  def change
    remove_column :external_references, :created_at, :datetime
    remove_column :external_references, :updated_at, :datetime
  end
end
