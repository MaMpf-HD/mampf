class RemoveHasVideoStreamFromMedia < ActiveRecord::Migration[5.1]
  def change
    remove_column :media, :has_video_stream?, :boolean
  end
end
