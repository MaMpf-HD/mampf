class CreateAssignmentSightings < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_sightings do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :assignment, null: false, foreign_key: true
      t.datetime :seen_at, null: false
      t.timestamps
    end
    add_index :assignment_sightings, [:user_id, :assignment_id], unique: true
  end
end
