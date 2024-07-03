# rubocop:disable Rails/
class AddPositionToSection < ActiveRecord::Migration[5.2]
  def change
    add_column :sections, :position, :integer
    Chapter.all.each do |chapter|
      chapter.sections.order(:number).each.with_index(1) do |section, index|
        section.update_column :position, index
      end
    end
  end
end
# rubocop:enable Rails/
