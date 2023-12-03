# rubocop:disable Rails/
class AddNewDesignToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :new_design, :boolean
  end
end
# rubocop:enable Rails/
