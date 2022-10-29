class AddPositionToItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :position, :integer
  end
end
