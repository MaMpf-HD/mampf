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
    # Maps user-facing type names to their corresponding model classes.
    # Used when creating new registerable entities through the item creation flow.
    REGISTERABLE_CLASSES = {
      "Tutorial" => Tutorial,
      "Talk" => Talk,
      "Enrollment Group" => Cohort,
      "Planning Survey" => Cohort,
      "Other Group" => Cohort
    }.freeze

    # Maps user-facing cohort type names to their corresponding purpose enum values.
    # Only relevant for Cohort registerables, determines the semantic meaning of the group.
    COHORT_TYPE_TO_PURPOSE = {
      "Enrollment Group" => :enrollment,
      "Planning Survey" => :planning,
      "Other Group" => :general
    }.freeze

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

    validate :validate_registerable_allows_campaigns, on: :create
    validate :validate_capacity_reduction, on: :update
    validate :validate_uniqueness_constraints
    before_destroy :ensure_campaign_is_draft

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

    # Determines if this item materializes to actual rosters.
    # Tutorials and Talks always materialize.
    # Cohorts only materialize if propagate_to_lecture is true.
    def materializes_to_roster?
      case registerable_type
      when "Tutorial", "Talk"
        true
      when "Cohort"
        registerable.propagate_to_lecture?
      else
        false
      end
    end

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

      def ensure_campaign_is_draft
        return if registration_campaign.draft?

        errors.add(:base, :frozen)
        throw(:abort)
      end

      def validate_uniqueness_constraints
        return unless registerable

        scope = Registration::Item.where(registerable: registerable)
        scope = scope.where.not(id: id) if persisted?

        return unless scope.exists?

        errors.add(:base, :already_in_other_campaign)
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
