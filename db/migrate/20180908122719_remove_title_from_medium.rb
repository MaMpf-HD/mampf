class RemoveTitleFromMedium < ActiveRecord::Migration[5.2]
  def change
    remove_column :media, :title, :string
  end
end
