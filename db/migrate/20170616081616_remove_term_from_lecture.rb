class RemoveTermFromLecture < ActiveRecord::Migration[5.1]
  def change
    remove_column :lectures, :term, :string
  end
end
