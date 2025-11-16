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
    validate :valid_status_transition, on: :update

    private

      def valid_status_transition
        return unless will_save_change_to_status?

        from = status_before_last_save
        to = status

        valid_transitions = {
          "draft" => ["open"],
          "open" => ["processing"],
          "processing" => ["completed"]
        }

        allowed = valid_transitions[from] || []
        return if allowed.include?(to)

        errors.add(:status, "cannot transition from #{from} to #{to}")
      end
  end
end
