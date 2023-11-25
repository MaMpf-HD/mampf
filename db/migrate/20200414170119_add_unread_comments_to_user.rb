class AddUnreadCommentsToUser < ActiveRecord::Migration[6.0]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :unread_comments, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
