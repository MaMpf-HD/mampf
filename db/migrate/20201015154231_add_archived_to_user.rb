class AddArchivedToUser < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :archived, :boolean
  end

  def down
    remove_column :users, :archived, :boolean
  end
end
