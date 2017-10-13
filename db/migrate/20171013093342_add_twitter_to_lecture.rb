class AddTwitterToLecture < ActiveRecord::Migration[5.1]
  def change
    add_column :lectures, :twitter, :text
  end
end
