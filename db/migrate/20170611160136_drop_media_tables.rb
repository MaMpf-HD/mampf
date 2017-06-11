class DropMediaTables < ActiveRecord::Migration[5.1]
  def change
    drop_table :media
    drop_table :external_references
    drop_table :manuscripts
    drop_table :video_files
    drop_table :video_streams
  end
end
