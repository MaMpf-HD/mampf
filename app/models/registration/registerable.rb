module Registration
  # Enables domain models (like Tutorial or Talk) to be the target of a registration campaign.
  # Enforces an interface for managing capacity and materializing the final list of
  # allocated users into the domain.
  module Registerable
    extend ActiveSupport::Concern

    included do
      has_many :registration_items, as: :registerable, class_name: "Registration::Item"

      before_update :validate_capacity_change_via_items
    end

    # Models including this concern must:
    # - Have a `capacity` integer column (nullable: nil = infinite capacity)
    # - Have a `skip_campaigns` boolean column (default: false, allows manual-only management)
    # - Implement #allocated_user_ids (returns array of user IDs)
    # - Implement #materialize_allocation!(user_ids:, campaign:)
    #
    # Note: Including Rosters::Rosterable provides default implementations for
    # the last two requirements.

    def allocated_user_ids
      raise(NotImplementedError,
            "#{self.class} must implement #allocated_user_ids. You may want to include Rosters::Rosterable.")
    end

    def materialize_allocation!(user_ids:, campaign:)
      raise(NotImplementedError,
            "#{self.class} must implement #materialize_allocation!. You may want to include Rosters::Rosterable.")
    end

    private

      # Enforces registration rules when updating capacity directly on the registerable.
      # Delegates validation to associated registration items to ensure consistency.
      def validate_capacity_change_via_items
        return unless will_save_change_to_capacity?

        registration_items.each do |item|
          error = item.validate_capacity_change_from_registerable!(capacity)

          next unless error

          _key, msg, options = error
          # Map :base errors from Item to :capacity errors on Registerable
          # We must translate the message here using the Item scope, otherwise
          # Rails will try to look it up in the Registerable scope (e.g. Lecture)
          # where it doesn't exist.
          translated_msg = I18n.t(
            "activerecord.errors.models.registration/item.attributes.base.#{msg}", **(options || {})
          )
          errors.add(:capacity, translated_msg)
          throw(:abort)
        end
      end
  end
end
