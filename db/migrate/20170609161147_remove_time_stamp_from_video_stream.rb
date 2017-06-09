class RemoveTimeStampFromVideoStream < ActiveRecord::Migration[5.1]
  def change
    remove_column :video_streams, :created_at, :datetime
    remove_column :video_streams, :updated_at, :datetime
  end
end
