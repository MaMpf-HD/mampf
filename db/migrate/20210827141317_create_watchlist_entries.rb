class CreateWatchlistEntries < ActiveRecord::Migration[6.1]
  def up
    create_table :watchlists # rubocop:todo Rails/CreateTableWithTimestamps

    create_table :watchlist_entries do |t|
      t.references :watchlist, null: false, foreign_key: true
      t.references :medium, null: false, foreign_key: true
      t.integer :medium_position

      t.timestamps
    end

    change_table :watchlists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :watchlist_entry, foreign_key: true

      t.timestamps
    end
  end

  def down
    drop_table :watchlists
    drop_table :watchlist_entries
  end
end
