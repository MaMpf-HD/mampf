class CreateVideoStreams < ActiveRecord::Migration[5.1]
  def change
    create_table :video_streams do |t|
      t.integer :width
      t.integer :height
      t.integer :size
      t.integer :length
      t.string :authoring_software

      t.timestamps
    end
  end
end
