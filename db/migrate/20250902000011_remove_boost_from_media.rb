class RemoveBoostFromMedia < ActiveRecord::Migration[8.0]
  def change
    remove_column :media, :boost, :float
  end
end
