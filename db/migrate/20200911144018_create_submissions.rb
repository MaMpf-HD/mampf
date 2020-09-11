class CreateSubmissions < ActiveRecord::Migration[6.0]
  def change
    create_table :submissions do |t|
      t.references :tutorial, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
      t.text :token

      t.timestamps
    end
  end
end
