module Registration
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

    enum :allocation_mode, { first_come_first_serve: 0,
                             preference_based: 1 }

    enum :status, { draft: 0,
                    open: 1,
                    processing: 2,
                    completed: 3 }

    validates :title, :registration_deadline, :allocation_mode, :status, presence: true

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
