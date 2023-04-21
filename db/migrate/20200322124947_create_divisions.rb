class CreateDivisions < ActiveRecord::Migration[6.0]
  def change
    create_table :divisions do |t|
      t.text :name
      t.references :program, foreign_key: true

      t.timestamps
    end
  end
end
