class AddForumIdToLecture < ActiveRecord::Migration[6.0]
  def change
    add_column :lectures, :forum_id, :integer
  end
end
