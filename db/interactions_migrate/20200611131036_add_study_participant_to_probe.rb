class AddStudyParticipantToProbe < ActiveRecord::Migration[6.0]
  def change
    add_column :probes, :study_participant, :string
  end
end
