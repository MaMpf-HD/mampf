class RenamePositionColumnInSectionTagJoin < ActiveRecord::Migration[6.0]
  def change
		rename_column :section_tag_joins, :position, :tag_position
  end
end
