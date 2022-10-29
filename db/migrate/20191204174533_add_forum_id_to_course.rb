class AddForumIdToCourse < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :forum_id, :integer
  end
end
