class AddNoteToAssessmentParticipations < ActiveRecord::Migration[8.0]
  def change
    add_column :assessment_participations, :note, :text
  end
end
