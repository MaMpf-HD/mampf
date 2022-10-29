class AddTitleToClicker < ActiveRecord::Migration[6.0]
  def change
    add_column :clickers, :title, :text
  end
end
