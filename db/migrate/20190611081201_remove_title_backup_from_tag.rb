class RemoveTitleBackupFromTag < ActiveRecord::Migration[6.0]
  def change

    remove_column :tags, :title_backup, :string
  end
end
