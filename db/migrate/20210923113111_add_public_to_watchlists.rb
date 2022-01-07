class AddPublicToWatchlists < ActiveRecord::Migration[6.1]
  def change
    add_column :watchlists, :public, :boolean, default: false
  end
end
