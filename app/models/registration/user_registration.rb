module Registration
  # Represents a single user's application within a campaign.
  # Tracks the status (pending/confirmed) and, for preference-based campaigns,
  # the specific ranking of an item.
  class UserRegistration < ApplicationRecord
    REJECTION_REASON_TYPE_CAPACITY = "capacity".freeze
    REJECTION_REASON_TYPE_MANUAL = "manual".freeze
    REJECTION_REASON_TYPE_POLICY = "policy".freeze

    REJECTION_REASON_CODE_SOLVER_UNASSIGNED = "solver_unassigned".freeze
    REJECTION_REASON_CODE_WITHDRAWN_BY_TEACHER = "withdrawn_by_teacher".freeze
    REJECTION_REASON_CODE_DEFERRED_DUE_TO_BLOCKER = "deferred_due_to_blocker".freeze

    REJECTION_REASON_CODE_TRANSLATION_ALIASES = {
      "institutional_email_mismatch" => "email_domain_not_allowed"
    }.freeze

    belongs_to :user

    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :user_registrations

    belongs_to :registration_item,
               class_name: "Registration::Item",
               inverse_of: :user_registrations

    belongs_to :rejection_policy,
               class_name: "Registration::Policy",
               optional: true

    # A user registration represents an application for a specific item.
    # Changing the target item is semantically a different application.
    # Therefore, the registration_item_id is immutable.
    attr_readonly :registration_item_id

    enum :status, { pending: 0, confirmed: 1, rejected: 2 }

    scope :with_open_rejection_reason, lambda {
      where(rejection_reason_code: nil)
        .or(
          where.not(
            rejection_reason_code: REJECTION_REASON_CODE_SOLVER_UNASSIGNED
          )
        )
    }

    scope :with_capacity_rejection_reason, lambda {
      where(rejection_reason_type: REJECTION_REASON_TYPE_CAPACITY)
    }

    scope :with_policy_rejection_reason, lambda {
      where(rejection_reason_type: REJECTION_REASON_TYPE_POLICY)
    }

    scope :not_overridden, lambda {
      where(rejection_overridden_at: nil)
    }

    before_validation :set_exclusive_assignment

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

    # first-come-first-served campaigns: no rank allowed, one row per user+campaign
    validates :preference_rank,
              absence: true,
              if: -> { registration_campaign.first_come_first_served? }

    after_create :increment_confirmed_counter
    after_update :update_confirmed_counter
    after_destroy :decrement_confirmed_counter

    # first-come-first-served campaigns: one row per user+campaign for tutorial + talk items
    # (exclusive_assignment == true)
    validates :user_id,
              uniqueness: {
                scope: :registration_campaign_id,
                conditions: -> { where(exclusive_assignment: true, preference_rank: nil) }
              },
              if: -> { exclusive_assignment && preference_rank.nil? }

    # first-come-first-served campaigns: one row per user + campaign + item
    validates :user_id,
              uniqueness: {
                scope: [:registration_campaign_id, :registration_item_id]
              },
              if: -> { registration_campaign.first_come_first_served? }

    def self.resolve_rejection_reason_label(reason_code:, fallback_label: nil)
      code = reason_code.to_s.presence
      return fallback_label if code.blank?

      translated_code = REJECTION_REASON_CODE_TRANSLATION_ALIASES.fetch(code, code)

      policy_key = "registration.policy.errors.#{translated_code}"
      return I18n.t(policy_key) if I18n.exists?(policy_key)

      reason_key = "registration.user_registration.reason_labels.#{translated_code}"
      return I18n.t(reason_key) if I18n.exists?(reason_key)

      fallback_label
    end

    def reject!(reason_type:, reason_code:, reason_label: nil,
                rejection_policy_id: nil,
                rejected_at: Time.current)
      update!(
        status: :rejected,
        rejection_reason_type: reason_type,
        rejection_reason_code: reason_code,
        rejection_reason_label: self.class.resolve_rejection_reason_label(
          reason_code: reason_code,
          fallback_label: reason_label
        ),
        rejection_policy_id: rejection_policy_id,
        rejected_at: rejected_at,
        rejection_overridden_at: nil
      )
    end

    def clear_rejection_decision!
      update!(
        rejection_reason_type: nil,
        rejection_reason_code: nil,
        rejection_reason_label: nil,
        rejection_policy_id: nil,
        rejected_at: nil,
        rejection_overridden_at: nil
      )
    end

    def resolved_rejection_reason_label
      self.class.resolve_rejection_reason_label(
        reason_code: rejection_reason_code,
        fallback_label: rejection_reason_label
      )
    end

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

      def set_exclusive_assignment
        self.exclusive_assignment =
          registration_campaign&.first_come_first_served? &&
          registration_item&.exclusive_assignment?
      end
  end
end
