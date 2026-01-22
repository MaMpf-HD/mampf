class CreateAssessmentAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_assessments, id: :uuid do |t|
      t.string :assessable_type, null: false
      t.bigint :assessable_id, null: false
      t.bigint :lecture_id, null: false

      t.string :title, null: false
      t.boolean :requires_points, default: false, null: false
      t.boolean :requires_submission, default: false, null: false
      t.decimal :total_points, precision: 10, scale: 2
      t.integer :status, default: 0, null: false
      t.datetime :visible_from
      t.datetime :due_at
      t.boolean :results_published, default: false, null: false

      t.timestamps
    end

    add_index :assessment_assessments, [:assessable_type, :assessable_id],
              name: "index_assessments_on_assessable"
    add_index :assessment_assessments, :lecture_id
    add_index :assessment_assessments, :status

    add_foreign_key :assessment_assessments, :lectures
  end
end
