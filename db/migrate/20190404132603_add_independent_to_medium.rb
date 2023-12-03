# rubocop:disable Rails/
class AddIndependentToMedium < ActiveRecord::Migration[5.2]
  def change
    add_column :media, :independent, :boolean
  end
end
# rubocop:enable Rails/
