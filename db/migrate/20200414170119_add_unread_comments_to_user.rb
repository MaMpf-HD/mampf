class AddUnreadCommentsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :unread_comments, :boolean, default: false
  end
end
