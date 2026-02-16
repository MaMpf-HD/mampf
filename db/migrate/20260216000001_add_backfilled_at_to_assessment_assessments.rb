class AddBackfilledAtToAssessmentAssessments < ActiveRecord::Migration[8.0]
  def change
    add_column :assessment_assessments, :backfilled_at, :datetime
  end
end
