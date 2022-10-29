class AddImportedManuscriptToMedium < ActiveRecord::Migration[5.2]
  def change
    add_column :media, :imported_manuscript, :boolean
  end
end
