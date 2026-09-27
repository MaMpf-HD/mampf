# Publishing the results again after taking them back mails nobody a second
# time, and results_published_at is cleared by taking them back.
class AddResultsNotifiedAtToAssessmentAssessments < ActiveRecord::Migration[8.0]
  def change
    add_column :assessment_assessments, :results_notified_at, :datetime
  end
end
