# A cohort may have tutors, like a tutorial, though it usually needs none:
# e.g. somebody who runs extra lessons for a group of students.
class CreateCohortTutorJoins < ActiveRecord::Migration[8.0]
  def change
    create_table :cohort_tutor_joins do |t|
      t.references :cohort, null: false, foreign_key: true, index: false
      t.references :tutor, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :cohort_tutor_joins, [:cohort_id, :tutor_id], unique: true
  end
end
