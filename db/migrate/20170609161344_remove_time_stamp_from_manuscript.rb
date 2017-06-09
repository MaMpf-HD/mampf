class RemoveTimeStampFromManuscript < ActiveRecord::Migration[5.1]
  def change
    remove_column :manuscripts, :created_at, :datetime
    remove_column :manuscripts, :updated_at, :datetime
  end
end
