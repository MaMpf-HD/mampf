class RenameVideoManuscriptSize < ActiveRecord::Migration[5.2]
  def change
    rename_column :media, :video_size, :video_size_dep
    rename_column :media, :manuscript_size, :manuscript_size_dep
  end
end
