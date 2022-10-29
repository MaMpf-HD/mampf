class AddTagsOrderToSection < ActiveRecord::Migration[5.2]
  def change
    add_column :sections, :tags_order, :text
  end
end
