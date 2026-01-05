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

      scope = TutorialMembership.joins(:tutorial)
                                .where(tutorials: { lecture_id: tutorial.lecture_id })
                                .where(user_id: user_id)
      scope = scope.where.not(id: id) if persisted?

      return unless scope.exists?

      errors.add(:base, :already_in_lecture_tutorial)
    end
end
