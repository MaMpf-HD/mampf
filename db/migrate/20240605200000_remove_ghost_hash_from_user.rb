class RemoveGhostHashFromUser < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :ghost_hash, :string
  end
end
