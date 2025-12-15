# Represents a user's assignment to a tutorial group, tracking the source campaign
# to distinguish between automated allocations and manual enrollments.
class TutorialMembership < ApplicationRecord
  belongs_to :user
  belongs_to :tutorial
  belongs_to :source_campaign, class_name: "RegistrationCampaign", optional: true
end
