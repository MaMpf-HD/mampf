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
                scope: [:registration_campaign_id, :registerable_type]
              }
    validate :registerable_type_consistency, on: :create
    validate :validate_capacity_frozen, on: :update
    validate :validate_capacity_reduction, on: :update
    validate :validate_planning_only_compliance
    validate :validate_uniqueness_constraints
    before_destroy :ensure_campaign_is_draft

    def item_capacity_used
      confirmed_registrations_count
    end

    def capacity_remained
      return nil if capacity.nil?

      capacity - item_capacity_used
    end

    def still_have_capacity?
      return true if capacity.nil?

      capacity_remained.positive?
    end

    def user_registered?(user)
      user_registrations.exists?(user_id: user.id, status: :confirmed)
    end

    def user_registrations_confirmed(user)
      user_registrations.where(user_id: user.id, status: :confirmed)
    end

    def title
      registerable&.registration_title || registerable&.title
    end

    def preference_rank(user)
      registration = user_registrations.find_by(user_id: user.id)
      registration&.preference_rank
    end

    def capacity_editable?
      return true if registration_campaign.draft?

      if registration_campaign.completed? ||
         (registration_campaign.processing? && registration_campaign.preference_based?)
        return false
      end

      true
    end

    # Validates if a capacity change initiated by the registerable (e.g. on a Tutorial
    # in the tutorial GUI) is permissible under the current campaign rules.
    def validate_capacity_change_from_registerable!(new_capacity)
      return [:base, :frozen] unless capacity_editable?

      unless valid_capacity_reduction?(new_capacity)
        confirmed_count = user_registrations.confirmed.count
        return [:base, :capacity_too_low, { count: confirmed_count }]
      end

      nil
    end

    def first_choice_count
      user_registrations.where(preference_rank: 1).count
    end

    private

      def valid_capacity_reduction?(new_capacity)
        return true if registration_campaign.draft?
        return true unless registration_campaign.first_come_first_served?
        return true if new_capacity.nil?

        confirmed_count = user_registrations.confirmed.count
        new_capacity >= confirmed_count
      end

      def validate_capacity_frozen
        return unless registerable&.will_save_change_to_capacity?
        return if capacity_editable?

        errors.add(:base, :frozen)
      end

      def validate_capacity_reduction
        return unless registerable&.will_save_change_to_capacity?

        return if valid_capacity_reduction?(capacity)

        confirmed_count = user_registrations.confirmed.count
        errors.add(:base, :capacity_too_low, count: confirmed_count)
      end

      def registerable_type_consistency
        # We use where.not(id: nil) to ensure we only look at persisted items
        # and ignore the current item (which is not yet persisted) or other
        # items currently being built in the same transaction/request.
        existing_item = registration_campaign.registration_items.where.not(id: nil).first
        return unless existing_item

        existing_type = existing_item.registerable_type

        if existing_type == "Lecture"
          errors.add(:base, :lecture_unique)
          return
        end

        return unless registerable_type != existing_type

        errors.add(:base, :mixed_types)
      end

      def ensure_campaign_is_draft
        return if registration_campaign.draft?

        errors.add(:base, :frozen)
        throw(:abort)
      end

      def validate_planning_only_compliance
        return unless registration_campaign&.planning_only?

        if registerable != registration_campaign.campaignable
          errors.add(:base, :planning_only_allows_only_lecture)
        end

        return unless registration_campaign.registration_items.where.not(id: id).any?

        errors.add(:base, :planning_only_allows_single_item)
      end

      def validate_uniqueness_constraints
        return unless registerable

        # If this is a planning campaign, we don't enforce uniqueness against other campaigns.
        # (Multiple planning campaigns for the same registerable are allowed).
        return if registration_campaign&.planning_only?

        # If this is a real campaign, ensure the registerable is not in any OTHER real campaign.
        scope = Registration::Item.joins(:registration_campaign)
                                  .where(registerable: registerable)
                                  .where(registration_campaigns: { planning_only: false })

        scope = scope.where.not(id: id) if persisted?

        return unless scope.exists?

        errors.add(:base, :already_in_other_campaign)
      end
  end
end
