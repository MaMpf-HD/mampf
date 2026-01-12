module Registration
  # Represents a time-bounded registration event (e.g. "Tutorial Registration").
  # Acts as a container for configuration (deadlines, allocation mode),
  # rules (policies), and the resulting user registrations.
  class Campaign < ApplicationRecord
    belongs_to :campaignable, polymorphic: true

    has_many :registration_items,
             class_name: "Registration::Item",
             dependent: :destroy,
             inverse_of: :registration_campaign

    # This association - which seems redundant at first glance - allows us to
    # enforce uniqueness constraints at the database level in addition to the
    # model level validations defined in UserRegistration (see the corresponding
    # indexes in the UserRegistration table in the schema):
    # - in preference  mode,  the same preference_rank cannot be used twice by
    #   the same user in the same campaign.
    # - in FCFS mode, the same user cannot register twice in the same campaign.
    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             dependent: :destroy,
             inverse_of: :registration_campaign

    has_many :registration_policies,
             class_name: "Registration::Policy",
             dependent: :destroy,
             inverse_of: :registration_campaign

    enum :allocation_mode, { first_come_first_served: 0,
                             preference_based: 1 }

    enum :status, { draft: 0,
                    open: 1,
                    closed: 2,
                    processing: 3,
                    completed: 4 }

    validates :title, :registration_deadline, :allocation_mode, :status, presence: true
    validates :planning_only, inclusion: { in: [true, false] }

    def evaluate_policies_for(user, phase: :registration)
      policy_engine.eligible?(user, phase: phase)
    end

    def policies_satisfied?(user, phase: :registration)
      evaluate_policies_for(user, phase: phase).pass
    end

    def user_registration_confirmed?(user)
      user_registrations.exists?(user_id: user.id, status: :confirmed)
    end

    private

      def policy_engine
        @policy_engine ||= Registration::PolicyEngine.new(self)
      end
  end
end
