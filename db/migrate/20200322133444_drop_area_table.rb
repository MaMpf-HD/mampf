class DropAreaTable < ActiveRecord::Migration[6.0]
  def change
  	drop_table :areas
  end
end
