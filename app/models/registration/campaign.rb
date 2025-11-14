module Registration
  class Campaign < ApplicationRecord
    belongs_to :campaignable, polymorphic: true

    has_many :registration_items,
             class_name: "Registration::Item",
             dependent: :destroy,
             inverse_of: :campaign

    has_many :user_registrations,
             class_name: "Registration::UserRegistration",
             dependent: :destroy,
             inverse_of: :campaign

    has_many :registration_policies,
             class_name: "Registration::Policy",
             dependent: :destroy,
             inverse_of: :campaign

    enum :allocation_mode, {
      first_come_first_serve: 0,
      preference_based: 1
    }

    enum :status, {
      draft: 0,
      open: 1,
      processing: 2,
      completed: 3
    }

    validates :title, presence: true
    validates :allocation_mode, presence: true
    validates :status, presence: true

    def evaluate_policies_for(user, phase: :registration)
      raise(NotImplementedError, "PolicyEngine integration pending (PR 2.2)")
    end

    def policies_satisfied?(user, phase: :registration)
      evaluate_policies_for(user, phase: phase)[:pass]
    rescue NotImplementedError
      true
    end

    def open_for_registrations?
      open?
    end

    def allocate!
      raise(NotImplementedError, "Allocation logic pending (PR 4.x)")
    end

    def finalize!
      raise(NotImplementedError, "Finalization logic pending (PR 4.x)")
    end

    def allocate_and_finalize!
      allocate!
      finalize!
    end
  end
end
