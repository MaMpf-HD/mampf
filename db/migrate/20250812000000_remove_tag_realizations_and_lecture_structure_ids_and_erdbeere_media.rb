class RemoveTagRealizationsAndLectureStructureIdsAndErdbeereMedia < ActiveRecord::Migration[8.0]
  def up
    # Remove columns
    remove_column :tags, :realizations, :text
    remove_column :lectures, :structure_ids, :text

    # Remove all media with sort == "Erdbeere"
    Media.where(sort: "Erdbeere").delete_all
  end

  def down
    # Add columns back
    add_column :tags, :realizations, :text
    add_column :lectures, :structure_ids, :text
    # Can't restore deleted media
  end
end
