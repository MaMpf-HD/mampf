class AddParticipationConfirmedAtToLectureMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :lecture_memberships, :participation_confirmed_at, :datetime
  end
end
