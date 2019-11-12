class AddContentToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :content, :text
  end
end
