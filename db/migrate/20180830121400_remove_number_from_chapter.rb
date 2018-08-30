class RemoveNumberFromChapter < ActiveRecord::Migration[5.2]
  def change
    remove_column :chapters, :number, :integer
  end
end
