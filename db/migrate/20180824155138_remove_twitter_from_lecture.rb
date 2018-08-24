class RemoveTwitterFromLecture < ActiveRecord::Migration[5.2]
  def change
    remove_column :lectures, :twitter, :text
  end
end
