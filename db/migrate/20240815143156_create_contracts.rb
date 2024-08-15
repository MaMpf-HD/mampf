class CreateContracts < ActiveRecord::Migration[7.1]
  def change
    create_table :contracts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lecture, null: false, foreign_key: true
      t.integer :role, null: false

      t.timestamps
    end
  end
end
