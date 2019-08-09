class AddInstanceToClicker < ActiveRecord::Migration[6.0]
  def change
    add_column :clickers, :instance, :text
  end
end
