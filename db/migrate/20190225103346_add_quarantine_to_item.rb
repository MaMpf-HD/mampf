# rubocop:disable Rails/
class AddQuarantineToItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :quarantine, :boolean
  end
end
# rubocop:enable Rails/
