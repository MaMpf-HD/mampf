module Registration
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
