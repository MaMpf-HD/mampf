class AddSortToLecture < ActiveRecord::Migration[6.0]
  def change
    add_column :lectures, :sort, :text
  end
end
