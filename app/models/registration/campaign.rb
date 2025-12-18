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
    validate :items_present_before_open, if: -> { status_changed? && open? }

    before_destroy :ensure_campaign_is_draft, prepend: true
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

    def evaluate_full_trace_for(user, phase: :registration)
      Registration::PolicyEngine.new(self).full_trace_for(user, phase: phase)
    end

    def open_for_registrations?
      open? && registration_deadline > Time.current
    end

    def open_for_withdrawals?
      open? && registration_deadline > Time.current
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

    def can_be_deleted?
      draft?
    end

    def total_registrations_count
      user_registrations.distinct.count(:user_id)
    end

    def confirmed_count
      user_registrations.confirmed.distinct.count(:user_id)
    end

    def pending_count
      # Users with at least one pending registration, but no confirmed registration.
      # This covers:
      # - Preference mode: All applicants before allocation (since none are confirmed).
      # - FCFS mode: Users on the waitlist who haven't secured a spot elsewhere in this campaign.
      user_registrations.pending
                        .where.not(user_id: user_registrations.confirmed.select(:user_id))
                        .distinct
                        .count(:user_id)
    end

    def rejected_count
      # Users with at least one rejected registration, but no confirmed or pending registration.
      # This explicitly queries for :rejected state, ensuring we don't count possibly other future
      # states.
      user_registrations.rejected
                        .where.not(user_id: user_registrations
                        .where(status: [:confirmed,
                                        :pending]).select(:user_id))
                        .distinct
                        .count(:user_id)
    end

    private

      def prerequisites_not_draft
        prereq_ids = registration_policies.select { |p| p.kind == "prerequisite_campaign" }
                                          .filter_map { |p| p.prerequisite_campaign_id.presence }

        return if prereq_ids.empty?

        Registration::Campaign.where(id: prereq_ids, status: :draft).find_each do |prereq|
          errors.add(:base, :prerequisite_is_draft, title: prereq.title)
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

      def items_present_before_open
        return unless registration_items.empty?

        errors.add(:base, :no_items)
      end

      def policy_engine
        @policy_engine ||= Registration::PolicyEngine.new(self)
      end
  end
end
