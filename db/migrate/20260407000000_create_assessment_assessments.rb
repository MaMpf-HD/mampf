class CreateAssessmentAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_assessments, id: :uuid do |t|
      t.string :assessable_type, null: false
      t.bigint :assessable_id, null: false
      t.bigint :lecture_id, null: false

      t.boolean :requires_points, default: false, null: false
      t.boolean :requires_submission, default: false, null: false
      t.decimal :total_points, precision: 10, scale: 2
      t.datetime :results_published_at

      t.timestamps
    end

    add_index :assessment_assessments, [:assessable_type, :assessable_id],
              name: "index_assessments_on_assessable"
    add_index :assessment_assessments, :lecture_id

    add_foreign_key :assessment_assessments, :lectures
  end
end
