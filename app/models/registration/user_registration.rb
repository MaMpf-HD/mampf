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
               class_name: "Registration::Item",
               inverse_of: :user_registrations

    enum :status, { pending: 0, confirmed: 1, rejected: 2 }

    validates :status, presence: true

    validate :ensure_item_belongs_to_campaign, if: :registration_item

    # preference-based campaigns: rank required unless it is a forced assignment
    # (confirmed with no rank).
    validates :preference_rank,
              presence: true,
              if: -> { registration_campaign.preference_based? && !confirmed? }

    # preference-based campaigns: rank must be unique per user+campaign.
    # We allow nil here because forced assignments (nil rank) are handled by the
    # partial index `index_reg_user_regs_unique_unranked` in the database.
    validates :preference_rank,
              uniqueness: {
                scope: [:user_id, :registration_campaign_id],
                allow_nil: true
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

    after_create :increment_confirmed_counter
    after_update :update_confirmed_counter
    after_destroy :decrement_confirmed_counter

    private

      # We use increment_counter/decrement_counter to update the counter cache
      # atomically without instantiating the item or running its validations.
      # This is the intended behavior for counter caches.
      # rubocop:disable Rails/SkipsModelValidations
      def increment_confirmed_counter
        return unless confirmed? && registration_item_id

        Registration::Item.increment_counter(:confirmed_registrations_count, registration_item_id)
      end

      def decrement_confirmed_counter
        return unless confirmed? && registration_item_id

        Registration::Item.decrement_counter(:confirmed_registrations_count, registration_item_id)
      end

      def update_confirmed_counter
        return unless saved_change_to_status? && registration_item_id

        old_status, new_status = saved_change_to_status
        was_confirmed = old_status == "confirmed"
        is_confirmed = new_status == "confirmed"

        if !was_confirmed && is_confirmed
          Registration::Item.increment_counter(:confirmed_registrations_count, registration_item_id)
        elsif was_confirmed && !is_confirmed
          Registration::Item.decrement_counter(:confirmed_registrations_count, registration_item_id)
        end
      end
      # rubocop:enable Rails/SkipsModelValidations

      def ensure_item_belongs_to_campaign
        return if registration_item.registration_campaign_id == registration_campaign_id

        errors.add(:registration_item, :must_belong_to_same_campaign)
      end
  end
end
