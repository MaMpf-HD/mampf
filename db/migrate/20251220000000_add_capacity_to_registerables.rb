class AddCapacityToRegisterables < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :capacity, :integer
    add_column :tutorials, :capacity, :integer
    add_column :talks, :capacity, :integer
  end
end
