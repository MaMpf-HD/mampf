class AddIndexesToMediaOnSortOnReleased < ActiveRecord::Migration[8.0]
  def change
    add_index :media, :sort
    add_index :media, :released
  end
end
