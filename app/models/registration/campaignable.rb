module Registration
  # Enables domain models (like Lecture) to host or own registration campaigns.
  # Provides the association to manage multiple campaigns (e.g., for tutorials or talks)
  # grouped under that specific domain object.
  module Campaignable
    extend ActiveSupport::Concern

    included do
      has_many :registration_campaigns,
               as: :campaignable,
               class_name: "Registration::Campaign",
               dependent: :destroy
    end
  end
end
