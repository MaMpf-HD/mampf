# Key sightings by assignment because points can exist without a Submission,
# and assignments without an assessment can still have a Submission.
# Each user needs a separate seen_at so partners do not clear each other's news.
class AssignmentSighting < ApplicationRecord
  belongs_to :user
  belongs_to :assignment

  validates :user_id, uniqueness: { scope: :assignment_id }

  # Two tabs can stamp the same sheet at once; one statement lets the unique
  # index settle it instead of raising on the loser.
  def self.stamp!(user:, assignment:, at: Time.current)
    upsert({ user_id: user.id, assignment_id: assignment.id, seen_at: at }, # rubocop:disable Rails/SkipsModelValidations
           unique_by: [:user_id, :assignment_id])
  end
end
