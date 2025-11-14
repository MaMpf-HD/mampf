module Registration
  class Item < ApplicationRecord
    belongs_to :campaign,
               class_name: "Registration::Campaign",
               inverse_of: :registration_items

    belongs_to :registerable, polymorphic: true

    validates :capacity,
              numericality: { greater_than: 0, allow_nil: true }
  end
end
