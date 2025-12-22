module Registration
  # Represents a selectable entry in a Registration::Campaign's catalog.
  # Acts as a wrapper around a domain object (Registerable, e.g. a Tutorial or Talk),
  # making it available for registration within a specific campaign context.
  # Think of it as a line item on a menu, distinct from the dish itself.
  #
  # A major reason for this indirection is to enforce referential integrity via
  # foreign keys. It ensures that users can only register for items explicitly
  # listed for the campaign, providing a database-level safety net that a simple
  # list of allowed IDs with application-level validation would lack.
  class Item < ApplicationRecord
    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :registration_items

    belongs_to :registerable, polymorphic: true

    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             dependent: :destroy

    validates :registerable_id,
              uniqueness: {
                scope: [:registration_campaign_id, :registerable_type]
              }
  end
end
