class AddStartChapterToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :start_chapter, :integer
  end
end
