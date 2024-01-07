# rubocop:disable Rails/
class RemoveNumbersFromSection < ActiveRecord::Migration[5.2]
  def change
    remove_column :sections, :number, :integer
    remove_column :sections, :number_alt, :string
  end
end
# rubocop:enable Rails/
