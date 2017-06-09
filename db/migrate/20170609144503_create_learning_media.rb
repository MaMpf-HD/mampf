class CreateLearningMedia < ActiveRecord::Migration[5.1]
  def change
    create_table :learning_media do |t|
      t.references :medium
      t.references :learning_asset
    end
  end
end
