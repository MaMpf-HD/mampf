# Represents a user's assignment to a tutorial group, tracking the source campaign
# to distinguish between automated allocations and manual enrollments.
class TutorialMembership < ApplicationRecord
  belongs_to :user
  belongs_to :tutorial
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true

  validate :unique_membership_per_lecture

  private

    def unique_membership_per_lecture
      return unless tutorial
      return unless user_id

      lecture_id = tutorial.lecture_id

      self.class.transaction do
        # Prevent race between exists? check and insert.
        # Uses (lecture_id, user_id) as lock key — avoid reusing
        # this (int, int) signature for unrelated entities.
        self.class.connection.execute(
          "SELECT pg_advisory_xact_lock(#{lecture_id}, #{user_id})"
        )

        scope = TutorialMembership.joins(:tutorial)
                                  .where(tutorials: { lecture_id: lecture_id })
                                  .where(user_id: user_id)
        scope = scope.where.not(id: id) if persisted?

        errors.add(:base, :already_in_lecture_tutorial) if scope.exists?
      end
    end
end
