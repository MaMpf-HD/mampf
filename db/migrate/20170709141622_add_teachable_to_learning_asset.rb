class AddTeachableToLearningAsset < ActiveRecord::Migration[5.1]
  def change
    add_reference :learning_assets, :teachable, polymorphic: true
  end
end
