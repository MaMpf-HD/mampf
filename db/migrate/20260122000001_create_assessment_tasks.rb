class CreateAssessmentTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_tasks, id: :uuid do |t|
      t.uuid :assessment_id, null: false
      t.string :title, null: false
      t.integer :position
      t.decimal :max_points, precision: 10, scale: 2, null: false
      t.text :description

      t.timestamps
    end

    add_index :assessment_tasks, :assessment_id
    add_index :assessment_tasks, [:assessment_id, :position]
    add_foreign_key :assessment_tasks, :assessment_assessments,
                    column: :assessment_id
  end
end
