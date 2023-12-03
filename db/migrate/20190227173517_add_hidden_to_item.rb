class AddHiddenToItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :hidden, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
