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

    def evaluate_full_trace_for(user, phase: :registration)
      Registration::PolicyEngine.new(self).full_trace_for(user, phase: phase)
    end

    def open_for_registrations?
      open?
    end

    def open_for_withdrawals?
      open?
    end

    # TODO: remove this
    def user_registered?(user)
      user_registrations.exists?(user_id: user.id, status: :confirmed)
    end

    def user_registrations_confirmed(user)
      user_registrations.where(user_id: user.id, status: :confirmed)
    end

    def user_registrations_last_updated(user)
      user_registrations.where(user_id: user.id).maximum(:updated_at)
    end

    def registerable_type
      registration_items.first&.registerable_type
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
