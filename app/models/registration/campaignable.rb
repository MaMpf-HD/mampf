module Registration
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
