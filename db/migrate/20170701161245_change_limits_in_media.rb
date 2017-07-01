class ChangeLimitsInMedia < ActiveRecord::Migration[5.1]
  def change
    remove_column :media, :video_size, :string
  end
end
