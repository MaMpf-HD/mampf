module Registration
  # Represents a selectable entry in a Registration::Campaign's catalog.
  # Acts as a wrapper around a domain object (Registerable, e.g. a Tutorial or Talk),
  # making it available for registration within a specific campaign context.
  # Think of it as a line item on a menu, distinct from the dish itself.
  #
  # Why is this indirection implemented?
  # - One major reason is to enforce referential integrity via foreign keys.
  # It ensures that users can only register for items explicitly listed for the
  # campaign, providing a database-level safety net that a simple list of allowed
  # IDs with application-level validation would lack.
  # - We separate the registration model (the item) from the domain model (the
  # registerable) to maintain clear boundaries between registration logic and
  # the core business logic of the registerable entities.
  # - It allows us to attach campaign-specific metadata to the item in the
  # future (e.g., special instructions) without modifying the underlying domain object.
  # Also, splitting up a registerable entity into multiple registration items
  # with different capacities or properties within the same campaign or
  # across different campaigns is possible, if needed, in the future
  class Item < ApplicationRecord
    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :registration_items

    belongs_to :registerable, polymorphic: true, autosave: true

    delegate :capacity, :capacity=, to: :registerable, allow_nil: true

    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             foreign_key: :registration_item_id,
             dependent: :destroy,
             inverse_of: :registration_item

    validates :registerable_id,
              uniqueness: {
                scope: :registerable_type
              }

    validate :validate_registerable_is_registerable, on: :create
    validate :validate_registerable_allows_campaigns, on: :create
    validate :validate_capacity_reduction, on: :update
    # Prepended so it runs before the dependent user_registrations are gone -
    # they are exactly what the guard has to see.
    before_destroy :ensure_item_is_removable, prepend: true

    REMOVABLE_CAMPAIGN_STATUSES = ["draft", "open", "closed"].freeze

    REMOVAL_BLOCKER_ERRORS = {
      status: :cannot_remove_in_status,
      registrations: :cannot_remove_with_registrations,
      allocation: :cannot_remove_after_allocation,
      last_item: :cannot_remove_last_item
    }.freeze

    def removal_blocker
      campaign = registration_campaign
      return :status unless campaign.status.in?(REMOVABLE_CAMPAIGN_STATUSES)
      return :registrations if user_registrations.exists?
      return :allocation if campaign.allocation_present?
      return nil if campaign.draft?
      return :last_item unless campaign.registration_items.where.not(id: id).exists?

      nil
    end

    def removal_blocker_message
      error = REMOVAL_BLOCKER_ERRORS[removal_blocker]
      return if error.nil?

      errors.generate_message(:base, error)
    end

    # The lock keeps a parallel registration from invalidating the decision
    # after it was made, and the rollback needs with_lock to open the
    # transaction - so do not call this from inside another one.
    def remove(delete_registerable: false)
      group = registerable
      removed = false

      registration_campaign.with_lock do
        removed = perform_removal(group, delete_registerable)
        removed = release_from_campaign_management(group) if removed && !delete_registerable
        raise(ActiveRecord::Rollback) unless removed
      end

      removed
    end

    def item_capacity_used
      confirmed_registrations_count
    end

    def remaining_capacity
      return nil if capacity.nil?

      capacity - item_capacity_used
    end

    def still_has_capacity?
      return true if capacity.nil?

      remaining_capacity.positive?
    end

    def user_registered?(user)
      user_registrations.exists?(user_id: user.id, status: :confirmed)
    end

    def title
      registerable&.registration_title || registerable&.title
    end

    def confirmed_user_ids
      user_registrations.confirmed.pluck(:user_id)
    end

    # Validates if a capacity change initiated by the registerable (e.g. on a Tutorial
    # in the tutorial GUI) is permissible under the current campaign rules.
    def validate_capacity_change_from_registerable!(new_capacity)
      unless valid_capacity_reduction?(new_capacity)
        confirmed_count = user_registrations.confirmed.count
        return [:base, :capacity_too_low, { count: confirmed_count }]
      end

      nil
    end

    def first_choice_count
      user_registrations.where(preference_rank: 1).count
    end

    delegate :exclusive_assignment?, to: :registerable

    private

      def valid_capacity_reduction?(new_capacity)
        return true if registration_campaign.draft?
        # After completion, we trust the user (teacher) to manage capacity vs roster size.
        return true if registration_campaign.completed?
        return true unless registration_campaign.first_come_first_served?
        return true if new_capacity.nil?

        confirmed_count = user_registrations.confirmed.count
        new_capacity >= confirmed_count
      end

      def validate_capacity_reduction
        return unless registerable&.will_save_change_to_capacity?

        return if valid_capacity_reduction?(capacity)

        confirmed_count = user_registrations.confirmed.count
        errors.add(:base, :capacity_too_low, count: confirmed_count)
      end

      def perform_removal(group, delete_registerable)
        return false unless destroy
        return true unless delete_registerable

        # Rosters::MaintenanceService locks the group to add a member, so hold
        # it here too - otherwise one arrives between the blocker check and
        # the destroy.
        group.lock!
        # The item is gone inside this transaction, so the group's own guards
        # decide from here on.
        group.registration_items.reset
        group.destroy && group.destroyed?
      end

      def release_from_campaign_management(group)
        return true unless group.respond_to?(:skip_campaigns)

        group.registration_items.reset
        group.update(skip_campaigns: true)
      end

      def ensure_item_is_removable
        # Set when the campaign is being destroyed and takes its items along.
        # ensure_campaign_is_discardable decided that; this guard only covers
        # taking a single item out of a campaign that stays.
        return if destroyed_by_association

        blocker = removal_blocker
        return if blocker.nil?

        errors.add(:base, REMOVAL_BLOCKER_ERRORS.fetch(blocker))
        throw(:abort)
      end

      # Registration::Registerable is what makes a model a campaign target -
      # a Lecture is a rosterable but not one of these, and the deletion path
      # would take the whole lecture with it.
      def validate_registerable_is_registerable
        return if registerable.nil? || registerable.is_a?(Registration::Registerable)

        errors.add(:registerable, :not_registerable)
      end

      # Registerables that have the skip_campaigns flag set are excluded from
      # becoming items in campaigns.
      def validate_registerable_allows_campaigns
        return unless registerable
        return unless registerable.respond_to?(:skip_campaigns?)
        return unless registerable.skip_campaigns?

        errors.add(:base, :registerable_not_managed_by_campaign)
      end
  end
end
