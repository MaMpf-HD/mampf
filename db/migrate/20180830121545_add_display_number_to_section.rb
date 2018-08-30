class AddDisplayNumberToSection < ActiveRecord::Migration[5.2]
  def change
    add_column :sections, :display_number, :text
  end
end
