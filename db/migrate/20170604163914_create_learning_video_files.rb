class CreateLearningVideoFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :learning_video_files do |t|
      t.references :learning_asset, foreign_key: true
      t.references :video_file, foreign_key: true

      t.timestamps
    end
  end
end
