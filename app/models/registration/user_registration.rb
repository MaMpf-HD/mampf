module Registration
  class UserRegistration < ApplicationRecord
    enum :status, {
      pending: 0,
      confirmed: 1,
      rejected: 2,
      limbo: 3
    }, prefix: true

    belongs_to :campaign,
               class_name: "Registration::Campaign",
               inverse_of: :user_registrations

    belongs_to :user

    belongs_to :item,
               class_name: "Registration::Item",
               optional: true

    validates :status, presence: true
    validates :user_id, uniqueness: { scope: :campaign_id }
  end
end
