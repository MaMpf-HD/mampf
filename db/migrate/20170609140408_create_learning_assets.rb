class CreateLearningAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :learning_assets do |t|
      t.string :title
      t.text :description
      t.string :project

      t.timestamps
    end
  end
end
