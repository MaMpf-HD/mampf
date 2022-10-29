class CreateItems < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.text :start_time
      t.text :sort
      t.integer :page
      t.text :description
      t.integer :number
      t.text :link
      t.text :explanation
      t.references :medium, foreign_key: true
      t.references :section, foreign_key: true

      t.timestamps
    end
  end
end
