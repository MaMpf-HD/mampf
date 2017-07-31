class RenameLearningAssetTypeToSort < ActiveRecord::Migration[5.1]
  def change
    rename_column :learning_assets, :type, :sort    
  end
end
