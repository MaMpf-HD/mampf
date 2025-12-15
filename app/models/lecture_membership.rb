# Represents a user's official membership in a lecture's roster, distinct from
# casual subscriptions, and tracks the source campaign for automated management.
class LectureMembership < ApplicationRecord
  belongs_to :user
  belongs_to :lecture
  belongs_to :source_campaign, class_name: "RegistrationCampaign", optional: true
end
