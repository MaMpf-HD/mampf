class RenameDescriptionToTitle < ActiveRecord::Migration[5.1]
  def change
    rename_column :learning_assets, :description, :title
  end
end
