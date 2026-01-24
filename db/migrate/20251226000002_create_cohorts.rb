class CreateCohorts < ActiveRecord::Migration[8.0]
  def change
    create_table :cohorts do |t|
      t.string :title
      t.text :description
      t.integer :capacity
      t.references :context, polymorphic: true, null: false
      t.integer :purpose, default: 0, null: false
      t.boolean :propagate_to_lecture, default: false, null: false

      t.timestamps
    end

    add_index :cohorts, [:context_type, :context_id, :purpose]

    add_check_constraint :cohorts,
                         "NOT (purpose = 2 AND propagate_to_lecture = true)",
                         name: "planning_cohorts_must_not_propagate"

    add_check_constraint :cohorts,
                         "NOT (purpose = 1 AND propagate_to_lecture = false)",
                         name: "enrollment_cohorts_must_propagate"
  end
end
