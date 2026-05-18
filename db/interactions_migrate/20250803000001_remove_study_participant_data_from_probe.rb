class RemoveStudyParticipantDataFromProbe < ActiveRecord::Migration[8.0]
  def up
    remove_column :probes, :study_participant
    remove_column :probes, :input
    remove_column :probes, :remark_id
  end

  def down
    add_column :probes, :study_participant, :string
    add_column :probes, :input, :text
    add_column :probes, :remark_id, :integer
  end
end
