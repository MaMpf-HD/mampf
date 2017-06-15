class CreateLearningAssets < ActiveRecord::Migration[5.1]
  def change
    create_table :learning_assets do |t|
      t.text :description
      t.string :type
      t.references :course, foreign_key: true
      t.references :lecture, foreign_key: true
      t.references :lesson, foreign_key: true

      t.timestamps
    end
  end
end
