class CreateMedia < ActiveRecord::Migration[5.1]
  def change
    create_table :media do |t|
      t.boolean :has_video_stream?
      t.boolean :has_video_file?
      t.boolean :has_video_thumbnail?
      t.boolean :has_manuscript?
      t.boolean :has_external_reference?
      t.text :video_stream_link
      t.text :video_file_link
      t.text :video_thumbnail_link
      t.text :manuscript_link
      t.text :external_reference_link
      t.integer :width
      t.integer :height
      t.integer :embedded_width
      t.integer :embedded_height
      t.integer :length
      t.bigint :video_size
      t.integer :pages
      t.integer :manuscript_size

      t.timestamps
    end
  end
end
