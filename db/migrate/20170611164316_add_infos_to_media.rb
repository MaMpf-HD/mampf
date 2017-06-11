class AddInfosToMedia < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :title, :string
    add_column :media, :author, :string
  end
end
