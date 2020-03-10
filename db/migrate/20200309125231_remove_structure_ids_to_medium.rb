class RemoveStructureIdsToMedium < ActiveRecord::Migration[6.0]
  def change
    remove_column :media, :structure_ids, :text
  end
end
