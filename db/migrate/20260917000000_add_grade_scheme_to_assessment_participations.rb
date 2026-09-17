# The scheme that gave a row its grade, nil for a grade entered by hand:
# re-applying a scheme may overwrite the first and must leave the second.
class AddGradeSchemeToAssessmentParticipations < ActiveRecord::Migration[8.0]
  def change
    add_reference :assessment_participations, :grade_scheme,
                  type: :uuid, null: true,
                  foreign_key: { to_table: :assessment_grade_schemes, on_delete: :nullify }
  end
end
