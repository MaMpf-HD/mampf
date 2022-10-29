class AddNewsToCourse < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :news, :text
  end
end
