class AddHiddenToSection < ActiveRecord::Migration[5.2]
  def change
    add_column :sections, :hidden, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
