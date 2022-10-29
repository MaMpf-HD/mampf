class CreateConsumptions < ActiveRecord::Migration[6.0]
  def change
    create_table :consumptions do |t|
      t.integer :medium_id
      t.text :sort
      t.text :mode

      t.timestamps
    end
  end
end
