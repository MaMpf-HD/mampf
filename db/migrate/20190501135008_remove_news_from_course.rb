class RemoveNewsFromCourse < ActiveRecord::Migration[6.0]
  def change
    remove_column :courses, :news, :text
  end
end
