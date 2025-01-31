class AddPublicToWatchlists < ActiveRecord::Migration[6.1]
  def up
    add_column :watchlists, :public, :boolean, default: false
  end

  def down
    remove_column :watchlists, :public, :boolean
  end
end
