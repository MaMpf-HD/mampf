class AddStudyParticipantToUser < ActiveRecord::Migration[6.0]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :study_participant, :boolean, default: false
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end
end
