class CreateLearningReferences < ActiveRecord::Migration[5.1]
  def change
    create_table :learning_references do |t|
      t.references :learning_asset, foreign_key: true
      t.references :external_reference, foreign_key: true

      t.timestamps
    end
  end
end
