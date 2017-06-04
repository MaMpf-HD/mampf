class CreateVideoFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :video_files do |t|
      t.integer :width
      t.integer :height
      t.integer :size
      t.integer :length
      t.string :codec

      t.timestamps
    end
  end
end
