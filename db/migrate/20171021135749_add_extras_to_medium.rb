class AddExtrasToMedium < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :extras_link, :text
    add_column :media, :extras_description, :text
  end
end
