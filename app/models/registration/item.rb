module Registration
  # Represents a selectable entry in a Registration::Campaign's catalog.
  # Acts as a wrapper around a domain object (Registerable, e.g. a Tutorial or Talk),
  # making it available for registration within a specific campaign context.
  # Think of it as a line item on a menu, distinct from the dish itself.
  class Item < ApplicationRecord
    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :registration_items

    belongs_to :registerable, polymorphic: true, autosave: true

    # NOTE: Always update capacity via item, not directly via registerable,
    # otherwise item's validations like :capacity_respects_confirmed_count
    # won't run. This works because we delegated :capacity to :registerable
    # in the model and have autosave: true on the registerable association
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
    before_destroy :ensure_campaign_is_draft

    def item_capacity_used
      # user_registrations.where(status: :confirmed).count
      confirmed_registrations_count
    end

    delegate :registerable_total_capacity_used, to: :registerable
    delegate :capacity_remained, to: :registerable

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
  end
end
