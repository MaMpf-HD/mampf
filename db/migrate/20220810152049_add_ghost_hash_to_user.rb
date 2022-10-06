class AddGhostHashToUser < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :ghost_hash, :string
  end

  def down
    remove_column :users, :ghost_hash, :string
  end
end
