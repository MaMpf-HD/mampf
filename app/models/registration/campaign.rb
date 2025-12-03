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

    validate :allocation_mode_frozen, on: :update
    validate :registration_deadline_future_if_open
    validate :prerequisites_not_draft, if: :open?

    before_destroy :ensure_campaign_is_draft
    before_destroy :ensure_not_referenced_as_prerequisite, prepend: true

    def locale_with_inheritance
      campaignable.try(:locale_with_inheritance) || campaignable.try(:locale)
    end

    def evaluate_policies_for(user, phase: :registration)
      policy_engine.eligible?(user, phase: phase)
    end

    def policies_satisfied?(user, phase: :registration)
      evaluate_policies_for(user, phase: phase).pass
    end

    def open_for_registrations?
      open? && registration_deadline > Time.current
    end

    def user_registration_confirmed?(user)
      user_registrations.exists?(user_id: user.id, status: :confirmed)
    end

    def can_be_deleted?
      draft?
    end

    private

      def prerequisites_not_draft
        registration_policies.each do |policy|
          next unless policy.kind == "prerequisite_campaign"

          prereq_id = policy.prerequisite_campaign_id
          next if prereq_id.blank?

          prereq = Registration::Campaign.find_by(id: prereq_id)
          errors.add(:base, :prerequisite_is_draft, title: prereq.title) if prereq&.draft?
        end
      end

      def ensure_not_referenced_as_prerequisite
        referencing_policies = Registration::Policy
                               .referencing_campaign(id)
                               .where.not(registration_campaign_id: id)
                               .includes(:registration_campaign)

        return unless referencing_policies.any?

        titles = referencing_policies.filter_map { |p| p.registration_campaign&.title }
                                     .uniq.join(", ")
        errors.add(:base, :referenced_as_prerequisite, titles: titles)
        throw(:abort)
      end

      def ensure_campaign_is_draft
        return if draft?

        errors.add(:base, :cannot_delete_active_campaign)
        throw(:abort)
      end

      def allocation_mode_frozen
        return unless allocation_mode_changed? && status_was != "draft"

        errors.add(:allocation_mode, :frozen)
      end

      def registration_deadline_future_if_open
        return unless open?
        return unless registration_deadline_changed? || status_changed?
        return if registration_deadline.blank?

        return unless registration_deadline <= Time.current

        errors.add(:registration_deadline, :must_be_in_future)
      end

      def policy_engine
        @policy_engine ||= Registration::PolicyEngine.new(self)
      end
  end
end
