class AddStructureIdsToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :structure_ids, :text
  end
end
