class RenameTagTitleToBackupTitle < ActiveRecord::Migration[6.0]
  def change
    rename_column :tags, :title, :title_backup
  end
end
