class AddLinkToLearningAsset < ActiveRecord::Migration[5.1]
  def change
    add_column :learning_assets, :link, :text
  end
end
