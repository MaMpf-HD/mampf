# rubocop:disable Rails/
class AddHiddenToItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :hidden, :boolean
  end
end
# rubocop:enable Rails/
