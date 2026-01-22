class CreateAssessmentParticipations < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_participations, id: :uuid do |t|
      t.uuid :assessment_id, null: false
      t.bigint :user_id, null: false
      t.bigint :tutorial_id

      t.decimal :points_total, precision: 10, scale: 2
      t.decimal :grade_numeric, precision: 2, scale: 1
      t.string :grade_text
      t.integer :status, default: 0, null: false
      t.datetime :submitted_at
      t.bigint :grader_id
      t.datetime :graded_at
      t.datetime :results_published_at
      t.boolean :published, default: false, null: false
      t.boolean :locked, default: false, null: false

      t.timestamps
    end

    add_index :assessment_participations, :assessment_id
    add_index :assessment_participations, :user_id
    add_index :assessment_participations, :tutorial_id
    add_index :assessment_participations, :grader_id
    add_index :assessment_participations, :status
    add_index :assessment_participations, [:assessment_id, :user_id],
              unique: true, name: "index_participations_on_assessment_and_user"
    add_foreign_key :assessment_participations, :assessment_assessments,
                    column: :assessment_id
    add_foreign_key :assessment_participations, :users, column: :user_id
    add_foreign_key :assessment_participations, :users, column: :grader_id
    add_foreign_key :assessment_participations, :tutorials

    # German grading scale constraint (1.0 = best, 5.0 = fail)
    # For non-German grading systems, remove this constraint:
    # execute "ALTER TABLE assessment_participations DROP CONSTRAINT valid_german_grades;"
    add_check_constraint :assessment_participations,
                         "grade_numeric IS NULL OR grade_numeric IN " \
                         "(1.0, 1.3, 1.7, 2.0, 2.3, 3.0, 3.7, 4.0, 5.0)",
                         name: "valid_german_grades"
  end
end
