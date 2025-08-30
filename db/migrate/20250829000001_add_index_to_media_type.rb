class AddIndexToMediaType < ActiveRecord::Migration[8.0]
  def change
    add_index :media, :type
  end
end
