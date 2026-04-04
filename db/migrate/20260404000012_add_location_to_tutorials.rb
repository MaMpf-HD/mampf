class AddLocationToTutorials < ActiveRecord::Migration[7.2]
  def change
    add_column :tutorials, :location, :string
  end
end
