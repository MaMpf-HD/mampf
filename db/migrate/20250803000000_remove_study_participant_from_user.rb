class RemoveStudyParticipantFromUser < ActiveRecord::Migration[8.0]
  def up
    remove_column :users, :study_participant
  end

  def down
    add_column :users, :study_participant, :boolean, default: false
  end
end
