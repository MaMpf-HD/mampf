class AddVideoSizeToMedia < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :video_size, :string
  end
end
