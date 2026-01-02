class CreateCohorts < ActiveRecord::Migration[8.0]
  def change
    create_table :cohorts do |t|
      t.string :title
      t.text :description
      t.integer :capacity
      t.references :context, polymorphic: true, null: false

      t.timestamps
    end
  end
end
