class AddLocationToTutorials < ActiveRecord::Migration[8.0]
  def change
    add_column :tutorials, :location, :string
  end
end
