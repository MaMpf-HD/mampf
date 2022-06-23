class AddNameToWatchlists < ActiveRecord::Migration[6.1]
  def change
    add_column :watchlists, :name, :string
  end
end
