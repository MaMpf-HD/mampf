class AddOpenToClicker < ActiveRecord::Migration[6.0]
  def change
    add_column :clickers, :open, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
