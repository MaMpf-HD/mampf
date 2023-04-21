class RemoveForumIdFromCourse < ActiveRecord::Migration[6.0]
  def change
    remove_column :courses, :forum_id, :integer
  end
end
