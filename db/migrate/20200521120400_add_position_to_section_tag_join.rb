class AddPositionToSectionTagJoin < ActiveRecord::Migration[6.0]
  def change
    add_column :section_tag_joins, :tag_position, :integer
    SectionTagJoin.all.each do |st|
      # rubocop:todo Rails/SkipsModelValidations
      st.update_column :tag_position, st.section&.tags_order&.index(st.tag_id)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
