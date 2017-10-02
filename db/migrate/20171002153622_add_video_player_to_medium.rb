class AddVideoPlayerToMedium < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :video_player, :string
  end
end
