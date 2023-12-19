# rubocop:disable Rails/
class AddOpenToClicker < ActiveRecord::Migration[6.0]
  def change
    add_column :clickers, :open, :boolean
  end
end
# rubocop:enable Rails/
