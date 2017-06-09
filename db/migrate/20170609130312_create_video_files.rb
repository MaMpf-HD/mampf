class CreateVideoFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :video_files do |t|
      t.integer :width
      t.integer :height
      t.bigint :size
      t.integer :frames_per_second
      t.string :codec

      t.timestamps
    end
  end
end
