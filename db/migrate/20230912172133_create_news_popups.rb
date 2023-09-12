class CreateNewsPopups < ActiveRecord::Migration[7.0]
  def change
    create_table :news_popups do |t|
      t.text :name
      t.boolean :active

      t.timestamps
    end
  end
end
