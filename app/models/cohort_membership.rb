class CohortMembership < ApplicationRecord
  belongs_to :cohort
  belongs_to :user
  belongs_to :source_campaign, class_name: "Registration::Campaign", optional: true
end
