class AddStructureIdsToLecture < ActiveRecord::Migration[6.0]
  def change
    add_column :lectures, :structure_ids, :text
  end
end
