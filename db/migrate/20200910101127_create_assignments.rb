class CreateAssignments < ActiveRecord::Migration[6.0]
  def change
    create_table :assignments do |t|
      t.references :lecture, null: false, foreign_key: true
      t.references :medium, null: true, foreign_key: false
      t.text :title
      t.datetime :deadline

      t.timestamps
    end
  end
end
