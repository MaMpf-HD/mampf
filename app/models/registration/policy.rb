module Registration
  class Policy < ApplicationRecord
    enum :phase, {
      registration: 0,
      finalization: 1,
      both: 2
    }, prefix: true

    belongs_to :campaign,
               class_name: "Registration::Campaign",
               inverse_of: :registration_policies

    validates :kind, presence: true
    validates :phase, presence: true
    validates :position, presence: true
    validates :position, uniqueness: { scope: :campaign_id }

    def evaluate(user)
      raise(NotImplementedError,
            "Policy evaluation pending (PR 2.2). Kind: #{kind}")
    end
  end
end
