module Registration
  # Represents a single user's application within a campaign.
  # Tracks the status (pending/confirmed) and, for preference-based campaigns,
  # the specific ranking of an item.
  class UserRegistration < ApplicationRecord
    belongs_to :user

    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :user_registrations

    belongs_to :registration_item,
               class_name: "Registration::Item"

    enum :status, { pending: 0, confirmed: 1, rejected: 2 }

    validates :status, presence: true

    validate :ensure_item_belongs_to_campaign, if: :registration_item

    # preference-based campaigns: rank required and unique per user+campaign
    # For the uniqueness validation, there is also a DB index to enforce it at the
    # database level (see the schema).
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

    # FCFS campaigns: one row per user+campaign
    # There is also a DB index to enforce it at the database level (see the schema).
    validates :user_id,
              uniqueness: {
                scope: :registration_campaign_id
              },
              if: -> { registration_campaign.first_come_first_served? }

    private

      def ensure_item_belongs_to_campaign
        return if registration_item.registration_campaign_id == registration_campaign_id

        errors.add(:registration_item, :must_belong_to_same_campaign)
      end
  end
end
