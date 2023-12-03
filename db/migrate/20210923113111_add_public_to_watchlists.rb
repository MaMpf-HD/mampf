class AddPublicToWatchlists < ActiveRecord::Migration[6.1]
  def up
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :watchlists, :public, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end

  def down
    remove_column :watchlists, :public, :boolean
  end
end
