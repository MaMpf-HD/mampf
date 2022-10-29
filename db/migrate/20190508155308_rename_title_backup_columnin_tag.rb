class RenameTitleBackupColumninTag < ActiveRecord::Migration[6.0]
  def change
    rename_column :tags, :title_backup, :title
  end
end
