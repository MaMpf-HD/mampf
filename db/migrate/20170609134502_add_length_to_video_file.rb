class AddLengthToVideoFile < ActiveRecord::Migration[5.1]
  def change
    add_column :video_files, :length, :integer
  end
end
