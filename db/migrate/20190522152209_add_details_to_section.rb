class AddDetailsToSection < ActiveRecord::Migration[6.0]
  def change
    add_column :sections, :details, :text
  end
end
