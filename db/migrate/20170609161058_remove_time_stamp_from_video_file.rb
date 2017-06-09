class RemoveTimeStampFromVideoFile < ActiveRecord::Migration[5.1]
  def change
    remove_column :video_files, :created_at, :datetime
    remove_column :video_files, :updated_at, :datetime
  end
end
