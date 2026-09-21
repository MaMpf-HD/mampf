class ChangeLecturesForAssessments < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :uses_exam_eligibility, :boolean,
               default: true, null: false
    add_column :lectures, :assignments_complete_at, :datetime
    remove_column :lectures, :muesli, :boolean
  end
end
