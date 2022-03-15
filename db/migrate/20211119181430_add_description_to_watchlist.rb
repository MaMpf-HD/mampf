class AddDescriptionToWatchlist < ActiveRecord::Migration[6.1]
  def up
    add_column :watchlists, :description, :string
  end

  def down
    remove_column :watchlists, :description, :string
  end
end
