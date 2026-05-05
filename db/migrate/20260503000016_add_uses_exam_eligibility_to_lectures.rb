class AddUsesExamEligibilityToLectures < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :uses_exam_eligibility, :boolean,
               default: true, null: false
  end
end
