class AddPositionToChapter < ActiveRecord::Migration[5.2]
  def change
    add_column :chapters, :position, :integer
    Lecture.all.each do |lecture|
      lecture.chapters.order(:number).each.with_index(1) do |chapter, index|
        chapter.update_column :position, index
      end
    end
  end
end
