# rubocop:disable Rails/
class AddHiddenToSection < ActiveRecord::Migration[5.2]
  def change
    add_column :sections, :hidden, :boolean
  end
end
# rubocop:enable Rails/
