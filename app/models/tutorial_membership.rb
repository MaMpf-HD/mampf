# Represents a user's assignment to a tutorial group, tracking the source campaign
# to distinguish between automated allocations and manual enrollments.
class TutorialMembership < ApplicationRecord
  belongs_to :user
  belongs_to :tutorial
  belongs_to :lecture
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true

  before_validation :set_lecture_from_tutorial

  validate :unique_membership_per_lecture
  validate :lecture_matches_tutorial

  private

    def set_lecture_from_tutorial
      self.lecture_id = tutorial&.lecture_id if lecture_id.nil?
    end

    def unique_membership_per_lecture
      return unless lecture_id && user_id

      scope = TutorialMembership.where(lecture_id: lecture_id, user_id: user_id)
      scope = scope.where.not(id: id) if persisted?

      errors.add(:base, :already_in_lecture_tutorial) if scope.exists?
    end

    def lecture_matches_tutorial
      return unless tutorial && lecture_id
      return if tutorial.lecture_id == lecture_id

      errors.add(:lecture, :does_not_match_tutorial)
    end
end
