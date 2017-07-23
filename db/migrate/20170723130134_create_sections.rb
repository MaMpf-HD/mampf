class CreateSections < ActiveRecord::Migration[5.1]
  def change
    create_table :sections do |t|
      t.references :chapter, foreign_key: true
      t.integer :number
      t.string :title
      t.string :number_alt

      t.timestamps
    end
  end
end
