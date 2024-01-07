class RemoveNumberFromItem < ActiveRecord::Migration[6.0]
  def change
    remove_column :items, :number, :integer
  end
end
