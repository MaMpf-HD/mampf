class CreateGradeSchemes < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_grade_schemes, id: :uuid do |t|
      t.uuid :assessment_id, null: false
      t.integer :kind, null: false, default: 0
      t.jsonb :config, null: false, default: {}
      t.string :version_hash
      t.datetime :applied_at
      t.bigint :applied_by_id
      t.boolean :active, null: false, default: false
      t.decimal :points_step, precision: 10, scale: 2, null: false, default: 1

      t.timestamps
    end

    add_index :assessment_grade_schemes, :assessment_id
    add_index :assessment_grade_schemes, :applied_by_id
    add_index :assessment_grade_schemes, :assessment_id,
              unique: true,
              where: "active = true",
              name: "idx_assessment_grade_schemes_one_active"

    add_foreign_key :assessment_grade_schemes, :assessment_assessments,
                    column: :assessment_id
    add_foreign_key :assessment_grade_schemes, :users,
                    column: :applied_by_id

    # The scheme that gave a row its grade, nil for a grade entered by hand:
    # re-applying a scheme may overwrite the first and must leave the second.
    add_reference :assessment_participations, :grade_scheme,
                  type: :uuid, null: true,
                  foreign_key: { to_table: :assessment_grade_schemes, on_delete: :nullify }
  end
end
