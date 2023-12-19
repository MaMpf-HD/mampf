# rubocop:disable Rails/
class AddConsentsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :consents, :boolean
  end
end
# rubocop:enable Rails/
