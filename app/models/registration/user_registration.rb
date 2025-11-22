module Registration
  class UserRegistration < ApplicationRecord
    # Represents a single user's application within a campaign.
    # Tracks the status (pending/confirmed) and, for preference-based campaigns,
    # the specific ranking of an item.
    belongs_to :user

    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :user_registrations

    belongs_to :registration_item,
               class_name: "Registration::Item",
               optional: true

    enum :status, { pending: 0, confirmed: 1, rejected: 2 }

    validates :status, presence: true

    # preference-based campaigns: rank required and unique per user+campaign
    validates :preference_rank,
              presence: true,
              uniqueness: {
                scope: [:user_id, :registration_campaign_id]
              },
              if: -> { registration_campaign.preference_based? }

    # FCFS campaigns: no rank allowed, one row per user+campaign
    validates :preference_rank,
              absence: true,
              if: -> { registration_campaign.first_come_first_served? }

    validates :user_id,
              uniqueness: {
                scope: :registration_campaign_id
              },
              if: -> { registration_campaign.first_come_first_served? }
  end
end
