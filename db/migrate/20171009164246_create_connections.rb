class CreateConnectionss < ActiveRecord::Migration[5.1]
  def change
    create_table :connections do |t|
      t.references :lecture, index: true, foreign_key: true
      t.references :connected_lecture, index: true

      t.timestamps null: false
    end

    add_foreign_key :connections, :lectures, column: :connected_lecture_id
    add_index :connections, [:lecture_id, :connected_lecture_id], unique: true
  end
end
