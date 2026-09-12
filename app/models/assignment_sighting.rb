# Key sightings by assignment because points can exist without a Submission,
# and assignments without an assessment can still have a Submission.
# Each user needs a separate seen_at so partners do not clear each other's news.
class AssignmentSighting < ApplicationRecord
  belongs_to :user
  belongs_to :assignment

  validates :user_id, uniqueness: { scope: :assignment_id }

  def self.stamp!(user:, assignment:, at: Time.current)
    find_or_initialize_by(user: user, assignment: assignment).update!(seen_at: at)
  end
end
