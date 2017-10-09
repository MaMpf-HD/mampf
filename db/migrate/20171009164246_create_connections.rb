class CreateConnections < ActiveRecord::Migration[5.1]
  def change
    create_table :connections do |t|
      t.references :lecture, index: true, foreign_key: true
      t.references :preceding_lecture, index: true

      t.timestamps null: false
    end

    add_foreign_key :connections, :lectures, column: :preceding_lecture_id
    add_index :connections, [:lecture_id, :preceding_lecture_id], unique: true
  end
end
