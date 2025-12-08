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
    validate :capacity_respects_confirmed_count, on: :update
    before_destroy :ensure_campaign_is_draft

    def title
      registerable&.registration_title || registerable&.title
    end

    private

      def capacity_respects_confirmed_count
        return if registration_campaign.draft?
        return unless registration_campaign.first_come_first_served?

        confirmed_count = user_registrations.confirmed.count
        return unless capacity < confirmed_count

        errors.add(:base, :capacity_too_low, count: confirmed_count)
      end

      def registerable_type_consistency
        existing_item = registration_campaign.registration_items.where.not(id: nil).first
        return unless existing_item

        existing_type = existing_item.registerable_type
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
