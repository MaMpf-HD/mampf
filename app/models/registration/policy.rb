module Registration
  # Represents a rule or constraint that a user must satisfy to register.
  # Acts as a gatekeeper (e.g. "Must have passed Exam X") that can be applied
  # at different phases (registration or finalization).
  class Policy < ApplicationRecord
    belongs_to :registration_campaign,
               class_name: "Registration::Campaign",
               inverse_of: :registration_policies

    enum :kind, { institutional_email: 0,
                  prerequisite_campaign: 1,
                  student_performance: 2 }

    enum :phase, { registration: 0,
                   finalization: 1,
                   both: 2 }

    validates :kind, :phase, presence: true
    validates :active, inclusion: { in: [true, false] }
    validates :position, uniqueness: { scope: :registration_campaign_id }

    acts_as_list scope: :registration_campaign
  end
end
