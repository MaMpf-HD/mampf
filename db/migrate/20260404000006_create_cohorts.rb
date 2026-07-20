class CreateCohorts < ActiveRecord::Migration[8.0]
  def change
    create_table :cohorts do |t|
      t.string :title, null: false
      t.text :description
      t.integer :capacity
      t.references :context, polymorphic: true, null: false
      t.boolean :propagate_to_lecture, default: false, null: false

      t.timestamps
    end
  end
end
