class RenameSectionContentToSectionTagJoin < ActiveRecord::Migration[5.1]
  def change
    rename_table :section_contents, :section_tag_joins        
  end
end
