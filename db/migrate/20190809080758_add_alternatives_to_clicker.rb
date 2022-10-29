class AddAlternativesToClicker < ActiveRecord::Migration[6.0]
  def change
    add_column :clickers, :alternatives, :integer
  end
end
