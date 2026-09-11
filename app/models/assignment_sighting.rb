# When somebody last opened their row of a sheet. The row is keyed by the
# sheet rather than by the hand-in because points sit on a participation and
# may have no hand-in behind them, while a hand-in on an old sheet has no
# participation - the sheet is what every row has. And it is per person, so
# a partner's look does not clear the other's marker.
class AssignmentSighting < ApplicationRecord
  belongs_to :user
  belongs_to :assignment

  validates :user_id, uniqueness: { scope: :assignment_id }

  def self.stamp!(user:, assignment:, at: Time.current)
    find_or_initialize_by(user: user, assignment: assignment).update!(seen_at: at)
  end
end
