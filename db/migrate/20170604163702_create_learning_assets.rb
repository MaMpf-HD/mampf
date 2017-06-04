class CreateLearningAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :learning_assets do |t|
      t.string :title
      t.string :author
      t.string :description

      t.timestamps
    end
  end
end
