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

    delegate :capacity, to: :registerable

    def capacity_used
      user_registrations.where(status: :confirmed).count
    end

    def capacity_remained
      capacity - capacity_used
    end

    def still_have_capacity?
      capacity_remained.positive?
    end
  end
end
