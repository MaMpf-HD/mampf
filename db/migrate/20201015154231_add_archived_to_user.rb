class AddArchivedToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :archived, :boolean
  end
end
