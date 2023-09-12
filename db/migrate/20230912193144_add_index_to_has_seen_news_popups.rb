class AddIndexToHasSeenNewsPopups < ActiveRecord::Migration[7.0]
  def change
    add_index :has_seen_news_popups, [:user_id, :news_popup_id], unique: true
  end
end
