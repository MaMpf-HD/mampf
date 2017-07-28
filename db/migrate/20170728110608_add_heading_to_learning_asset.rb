class AddHeadingToLearningAsset < ActiveRecord::Migration[5.1]
  def change
    add_column :learning_assets, :heading, :string
  end
end
