class RemoveBooleansFromMedium < ActiveRecord::Migration[5.1]
  def change
    remove_column :media, :has_video_stram?, :boolean
    remove_column :media, :has_video_file?, :boolean
    remove_column :media, :has_video_thumbnail?, :boolean
    remove_column :media, :has_manuscript?, :boolean
    remove_column :media, :has_external_reference?, :boolean
  end
end
