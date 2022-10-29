class AddPositionToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :position, :integer
  end
end
