class CreateLearningManuscripts < ActiveRecord::Migration[5.1]
  def change
    create_table :learning_manuscripts do |t|
      t.references :learning_asset, foreign_key: true
      t.references :manuscript, foreign_key: true

      t.timestamps
    end
  end
end
