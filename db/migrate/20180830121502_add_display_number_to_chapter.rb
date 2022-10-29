class AddDisplayNumberToChapter < ActiveRecord::Migration[5.2]
  def change
    add_column :chapters, :display_number, :text
  end
end
