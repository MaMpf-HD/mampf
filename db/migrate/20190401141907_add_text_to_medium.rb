class AddTextToMedium < ActiveRecord::Migration[5.2]
  def change
    add_column :media, :text, :text
  end
end
