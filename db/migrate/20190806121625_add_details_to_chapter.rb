class AddDetailsToChapter < ActiveRecord::Migration[6.0]
  def change
    add_column :chapters, :details, :text
  end
end
