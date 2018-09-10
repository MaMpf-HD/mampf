class AddRefNumberToItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ref_number, :text
  end
end
