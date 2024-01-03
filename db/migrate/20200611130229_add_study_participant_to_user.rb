# rubocop:disable Rails/
class AddStudyParticipantToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :study_participant, :boolean, default: false
  end
end
# rubocop:enable Rails/
