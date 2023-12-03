class RemoveALotOfColumnsFromMedium < ActiveRecord::Migration[5.2]
  def change
    remove_column :media, :width, :integer
    remove_column :media, :height, :integer
    remove_column :media, :embedded_width, :integer
    remove_column :media, :embedded_height, :integer
    remove_column :media, :length, :string
    remove_column :media, :pages, :integer
    remove_column :media, :video_size_dep, :string
    remove_column :media, :manuscript_size_dep, :string
    remove_column :media, :authoring_software, :string
    remove_column :media, :video_player, :string
  end
end
