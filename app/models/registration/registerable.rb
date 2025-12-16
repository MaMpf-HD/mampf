module Registration
  module Registerable
    extend ActiveSupport::Concern

    included do
      has_many :registration_items, as: :registerable, class_name: "Registration::Item"

      before_update :validate_capacity_change_via_items
    end

    # Models including this concern must:
    # - Have a `capacity` integer column (nullable: nil = infinite capacity)
    # - Implement #allocated_user_ids (returns array of user IDs)
    # - Implement #materialize_allocation!(user_ids:, campaign:)

    def registerable_total_capacity_used
      registration_items&.sum(&:confirmed_registrations_count) || 0
    end

    def capacity_remained
      return nil if capacity.nil?

      capacity - registerable_total_capacity_used
    end

    def allocated_user_ids
      raise(NotImplementedError, "Registerable must implement #allocated_user_ids")
    end

    def materialize_allocation!(user_ids:, campaign:)
      raise(NotImplementedError, "Registerable must implement #materialize_allocation!")
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
