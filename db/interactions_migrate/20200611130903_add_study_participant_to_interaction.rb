class AddStudyParticipantToInteraction < ActiveRecord::Migration[6.0]
  def change
    add_column :interactions, :study_participant, :string
  end
end
