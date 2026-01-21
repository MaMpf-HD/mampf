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

    has_many :users, -> { distinct }, through: :user_registrations

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

    validates :registration_deadline, :allocation_mode, :status, presence: true
    validates :description, length: { maximum: 100 }

    validate :allocation_mode_frozen, on: :update
    validate :cannot_revert_to_draft, on: :update
    validate :ensure_editable, on: :update
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

    def lecture_based?
      campaignable_type == "Lecture"
    end

    def exam_based?
      campaignable_type == "Exam"
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

    def user_registrations_grouped_by_user
      user_registrations.includes(:user, :registration_item)
                        .joins(:user)
                        .order("users.name")
                        .group_by(&:user)
    end

    def finalize!
      # Protect against concurrent finalization attempts via locking
      with_lock do
        return if completed?

        Registration::AllocationMaterializer.new(self).materialize!

        # Reject all remaining pending registrations so the state is explicit
        # rubocop:disable Rails/SkipsModelValidations
        user_registrations.pending.update_all(status: :rejected)
        # rubocop:enable Rails/SkipsModelValidations

        update!(status: :completed)
      end
    end

    # Returns users registered in this campaign who are not assigned to any group
    # of the same type within the campaignable (Lecture).
    # This respects the materialization logic: if a user is assigned via another campaign
    # (or manually), they are considered "assigned" and thus not a candidate here.
    def unassigned_users
      return User.none if draft?

      types = registration_items.pluck(:registerable_type).uniq

      # Find users already assigned to ANY item of these types in the lecture.
      allocated_user_ids = types.flat_map do |type|
        klass = type.constantize
        scope = if type == "Cohort"
          klass.where(context: campaignable)
        else
          klass.where(lecture: campaignable)
        end

        # Optimization: Use direct SQL join if the standard :members association exists.
        # This avoids N+1 queries on instances.
        if klass.reflect_on_association(:members)
          scope.joins(:members).pluck("users.id")
        else
          # Fallback: Load instances and use the Rosterable interface.
          # This is slower but guarantees correctness if the association name differs.
          scope.flat_map(&:allocated_user_ids)
        end
      end.uniq

      # Return registered users who are not in the allocated list
      # We look at all users who have at least one registration entry in this campaign
      # (regardless of status, as they are "candidates" until assigned elsewhere)
      users.where.not(id: allocated_user_ids)
    end

    def roster_group_type
      registration_items.first&.registerable_type&.tableize || "tutorials"
    end

    private

      def ensure_editable
        return unless completed?
        return unless changed?

        errors.add(:base, :already_finalized) unless status_changed?
      end

      def prerequisites_not_draft
        prereq_ids = registration_policies.select { |p| p.kind == "prerequisite_campaign" }
                                          .filter_map { |p| p.prerequisite_campaign_id.presence }

        return if prereq_ids.empty?

        Registration::Campaign.where(id: prereq_ids, status: :draft).find_each do |prereq|
          errors.add(:base, :prerequisite_is_draft, description: prereq.description)
        end
      end

      def ensure_not_referenced_as_prerequisite
        referencing_policies = Registration::Policy
                               .referencing_campaign(id)
                               .where.not(registration_campaign_id: id)
                               .includes(:registration_campaign)

        return unless referencing_policies.any?

        descriptions = referencing_policies.filter_map { |p| p.registration_campaign&.description }
                                           .uniq.join(", ")
        errors.add(:base, :referenced_as_prerequisite, descriptions: descriptions)
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

      def cannot_revert_to_draft
        return unless status_changed? && draft?

        errors.add(:status, :cannot_revert_to_draft)
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
