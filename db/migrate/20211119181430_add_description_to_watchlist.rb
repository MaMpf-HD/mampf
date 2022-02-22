class AddDescriptionToWatchlist < ActiveRecord::Migration[6.1]
  def change
    add_column :watchlists, :description, :string
  end
end
