class AddLengthToVideoStream < ActiveRecord::Migration[5.1]
  def change
    add_column :video_streams, :length, :integer
  end
end
