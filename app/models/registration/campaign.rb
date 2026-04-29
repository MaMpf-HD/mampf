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

    has_many :status_events,
             class_name: "Registration::StatusEvent",
             foreign_key: :registration_campaign_id,
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
    before_destroy :collect_registerables_for_release, prepend: true
    after_destroy :release_registerables_from_campaign

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

    def latest_finalization_status_events
      return Registration::StatusEvent.none if last_finalization_correlation_id.blank?

      status_events.where(correlation_id: last_finalization_correlation_id)
    end

    def can_be_deleted?
      draft?
    end

    def total_registrations_count
      return user_registrations.map(&:user_id).uniq.size if user_registrations.loaded?

      user_registrations.distinct.count(:user_id)
    end

    def confirmed_count
      user_registrations.confirmed.distinct.count(:user_id)
    end

    def latest_finalization_confirmed_count
      return confirmed_count if last_finalization_correlation_id.blank?

      latest_finalization_user_ids_for(
        Registration::StatusEvent::ACTION_SYSTEM_CONFIRM
      ).size
    end

    def pending_count
      user_registrations.pending
                        .where.not(user_id: user_registrations.confirmed.select(:user_id))
                        .distinct
                        .count(:user_id)
    end

    def rejected_count
      user_registrations.rejected
                        .where.not(user_id: user_registrations
                        .where(status: [:confirmed,
                                        :pending]).select(:user_id))
                        .distinct
                        .count(:user_id)
    end

    def latest_finalization_rejected_count
      latest_finalization_auto_rejected_count
    end

    def latest_finalization_auto_rejected_count
      return rejected_users.size if last_finalization_correlation_id.blank?

      auto_rejected_user_ids = latest_finalization_rejected_user_ids(
        reason_type: Registration::StatusEvent::REASON_TYPE_POLICY
      )
      confirmed_user_ids = latest_finalization_user_ids_for(
        Registration::StatusEvent::ACTION_SYSTEM_CONFIRM
      )

      (auto_rejected_user_ids - confirmed_user_ids).size
    end

    def latest_finalization_unassigned_count
      return unassigned_non_rejected_users.size if last_finalization_correlation_id.blank?

      unassigned_user_ids = latest_finalization_rejected_user_ids_excluding(
        reason_type: Registration::StatusEvent::REASON_TYPE_POLICY
      )
      confirmed_user_ids = latest_finalization_user_ids_for(
        Registration::StatusEvent::ACTION_SYSTEM_CONFIRM
      )
      auto_rejected_user_ids = latest_finalization_rejected_user_ids(
        reason_type: Registration::StatusEvent::REASON_TYPE_POLICY
      )

      (unassigned_user_ids - confirmed_user_ids - auto_rejected_user_ids).size
    end

    def user_registrations_grouped_by_user
      user_registrations.includes(:user, :registration_item)
                        .joins(:user)
                        .order("users.name")
                        .group_by(&:user)
    end

    def finalize!
      with_lock do
        return if completed?

        correlation_id = SecureRandom.uuid
        auto_reject_outcomes = auto_reject_outcomes_by_registration
        auto_reject_registration_ids = auto_reject_outcomes.keys
        confirmed_registrations = user_registrations.confirmed
                                                    .where.not(id: auto_reject_registration_ids)
                                                    .includes(:user)
                                                    .to_a
        auto_rejected_registrations = user_registrations.confirmed
                                                        .where(id: auto_reject_registration_ids)
                                                        .includes(:user)
                                                        .to_a
        pending_registrations = user_registrations.pending.includes(:user).to_a

        reject_registrations!(auto_rejected_registrations)
        reject_registrations!(pending_registrations)

        Registration::AllocationMaterializer.new(self).materialize!

        Registration::StatusEventWriter.call(
          registrations: confirmed_registrations,
          action: Registration::StatusEvent::ACTION_SYSTEM_CONFIRM,
          correlation_id: correlation_id,
          snapshot: lambda do |_registration|
            { "label" => "Confirmed by finalization" }
          end
        )

        Registration::StatusEventWriter.call(
          registrations: auto_rejected_registrations,
          action: Registration::StatusEvent::ACTION_SYSTEM_REJECT,
          reason_type: lambda do |registration|
            auto_reject_reason_type(auto_reject_outcomes[registration.id])
          end,
          reason_code: lambda do |registration|
            auto_reject_reason_code(auto_reject_outcomes[registration.id])
          end,
          correlation_id: correlation_id,
          snapshot: lambda do |registration|
            auto_reject_snapshot(auto_reject_outcomes[registration.id])
          end
        )

        Registration::StatusEventWriter.call(
          registrations: pending_registrations,
          action: Registration::StatusEvent::ACTION_SYSTEM_REJECT,
          reason_type: rejection_reason_type,
          reason_code: rejection_reason_code,
          correlation_id: correlation_id,
          snapshot: lambda do |_registration|
            rejection_snapshot
          end
        )

        update!(status: :completed,
                last_finalization_correlation_id: correlation_id)
      end
    end

    def reset_allocation_results!
      with_lock do
        subquery = Registration::UserRegistration
                   .select(:user_id)
                   .where(registration_campaign_id: id)
                   .group(:user_id)
                   .having("count(*) > 1")

        user_registrations
          .where(preference_rank: nil)
          .where(user_id: subquery)
          .delete_all

        # rubocop:disable Rails/SkipsModelValidations
        user_registrations.update_all(
          status: :pending,
          materialized_at: nil,
          updated_at: Time.current
        )

        registration_items.update_all(
          confirmed_registrations_count: 0,
          updated_at: Time.current
        )

        update_columns(last_allocation_calculated_at: nil)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    # Returns users registered in this campaign who are not currently allocated
    # to any matching registerable within the campaignable.
    #
    # Lecture roster membership alone does not affect this query. A user is only
    # considered assigned once they appear in the allocated user IDs of the
    # relevant tutorials, talks, or cohorts, whether that happened manually or
    # through another campaign. A user is considered unassigned if they haven't
    # secured a spot in any of the campaign's registerables, even if they are
    # members of the lecture roster.
    #
    # When preload_registrations is true, the returned relation also eager-loads
    # the registration data needed by the "unassigned side panel" and orders by
    # name and email.
    def unassigned_users(preload_registrations: false)
      return User.none if draft?

      relation = unassigned_users_relation
      return relation unless preload_registrations

      preload_candidate_users(relation)
    end

    def unassigned_non_rejected_users
      return [] if draft?

      candidate_users = preload_candidate_users(unassigned_users_relation)
      candidate_users.reject { |user| strictly_rejected_candidate_user?(user) }
    end

    def rejected_users
      return [] if draft?

      candidate_users = preload_candidate_users(unassigned_users_relation)
      candidate_users.select { |user| strictly_rejected_candidate_user?(user) }
    end

    def roster_group_type
      items = if association(:registration_items).loaded?
        registration_items
      else
        registration_items.limit(1)
      end
      items.first&.registerable_type&.tableize || "tutorials"
    end

    private

      def unassigned_users_relation
        allocated_ids = registerable_types.flat_map do |type|
          allocated_user_ids_for_type(type)
        end.uniq

        users.where.not(id: allocated_ids)
      end

      def preload_candidate_users(relation)
        relation.includes(
          user_registrations: [
            :registration_campaign,
            :status_events,
            { registration_item: :registerable }
          ]
        ).order(:name, :email).to_a
      end

      def latest_finalization_user_ids_for(action)
        latest_finalization_status_events
          .where(action: action)
          .joins(:registration)
          .distinct
          .pluck("#{Registration::UserRegistration.table_name}.user_id")
      end

      def latest_finalization_rejected_user_ids(reason_type:)
        latest_finalization_status_events
          .where(action: Registration::StatusEvent::ACTION_SYSTEM_REJECT,
                 reason_type: reason_type)
          .joins(:registration)
          .distinct
          .pluck("#{Registration::UserRegistration.table_name}.user_id")
      end

      def latest_finalization_rejected_user_ids_excluding(reason_type:)
        latest_finalization_status_events
          .where(action: Registration::StatusEvent::ACTION_SYSTEM_REJECT)
          .joins(:registration)
          .pluck(
            "#{Registration::UserRegistration.table_name}.user_id",
            "#{Registration::StatusEvent.table_name}.reason_type"
          )
          .select { |_, event_reason_type| event_reason_type != reason_type }
          .map(&:first)
          .uniq
      end

      def strictly_rejected_candidate_user?(user)
        reject_event = latest_candidate_status_event(
          user,
          Registration::StatusEvent::ACTION_SYSTEM_REJECT,
          Registration::StatusEvent::ACTION_TEACHER_REJECT
        )
        return false unless reject_event

        reinstate_event = latest_candidate_status_event(
          user,
          Registration::StatusEvent::ACTION_TEACHER_REINSTATE
        )
        return false if newer_candidate_event?(reinstate_event, reject_event)

        reject_event.action == Registration::StatusEvent::ACTION_TEACHER_REJECT ||
          [Registration::StatusEvent::REASON_TYPE_POLICY,
           Registration::StatusEvent::REASON_TYPE_MANUAL].include?(reject_event.reason_type)
      end

      def latest_candidate_status_event(user, *actions)
        relevant_candidate_registrations(user)
          .flat_map { |registration| Array(registration.try(:status_events)) }
          .select { |event| actions.include?(event.action) }
          .max_by { |event| candidate_event_sort_key(event) }
      end

      def relevant_candidate_registrations(user)
        user.user_registrations.select do |registration|
          registration.registration_campaign_id == id
        end
      end

      def newer_candidate_event?(left, right)
        return false unless left

        (candidate_event_sort_key(left) <=> candidate_event_sort_key(right)) == 1
      end

      def candidate_event_sort_key(event)
        [event.created_at, event.id.to_s]
      end

      def ensure_editable
        return unless status_was == "completed"
        return unless changed?

        errors.add(:base, :already_finalized)
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

      def collect_registerables_for_release
        @registerables_to_release = registration_items
                                    .filter_map(&:registerable)
                                    .select { |r| r.respond_to?(:skip_campaigns) }
      end

      def auto_reject_outcomes_by_registration
        Registration::FinalizationGuard.new(self)
                                       .policy_violations
                                       .each_with_object({}) do |violation, grouped|
          next unless violation[:classification] ==
                      Registration::FinalizationGuard::CLASSIFICATION_AUTO_REJECT

          grouped[violation[:registration_id]] ||= violation
        end
      end

      def reject_registrations!(registrations)
        return if registrations.empty?

        # rubocop:disable Rails/SkipsModelValidations
        user_registrations.where(id: registrations.map(&:id))
                          .update_all(status: :rejected)
        # rubocop:enable Rails/SkipsModelValidations
      end

      def auto_reject_reason_type(outcome)
        outcome&.fetch(:reason_type, nil)&.to_s
      end

      def auto_reject_reason_code(outcome)
        outcome&.fetch(:reason_code, nil)&.to_s
      end

      def auto_reject_snapshot(outcome)
        snapshot = outcome&.fetch(:snapshot, nil)
        return snapshot.deep_stringify_keys if snapshot.is_a?(Hash) && snapshot.present?

        message = outcome&.fetch(:message, nil)
        return { "label" => message } if message.present?

        { "label" => "Rejected by finalization" }
      end

      def rejection_reason_type
        return Registration::StatusEvent::REASON_TYPE_CAPACITY if preference_based?

        nil
      end

      def rejection_reason_code
        return Registration::StatusEvent::REASON_CODE_SOLVER_UNASSIGNED if preference_based?

        nil
      end

      def rejection_snapshot
        return { "label" => "Not placed by solver" } if preference_based?

        { "label" => "Rejected by finalization" }
      end

      def release_registerables_from_campaign
        return if @registerables_to_release.blank?

        ids_by_type = @registerables_to_release.group_by(&:class)
        ids_by_type.each do |klass, records|
          # rubocop:disable Rails/SkipsModelValidations
          klass.where(id: records.map(&:id)).update_all(skip_campaigns: true)
          # rubocop:enable Rails/SkipsModelValidations
        end
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
        return unless open? || (draft? && registration_deadline_changed?)
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

      def registerable_types
        if registration_items.loaded?
          registration_items.map(&:registerable_type).uniq
        else
          registration_items.pluck(:registerable_type).uniq
        end
      end

      def allocated_user_ids_for_type(type)
        assoc = type.tableize.to_sym

        # Optimization: Use eager-loaded associations on the campaignable logic
        if campaignable.respond_to?(assoc) && campaignable.association(assoc).loaded?
          return campaignable.public_send(assoc).flat_map(&:allocated_user_ids)
        end

        klass = type.constantize
        scope = fetch_scope_for_type(klass, type)
        fetch_ids_from_scope(klass, scope)
      end

      def fetch_scope_for_type(klass, type)
        if type == "Cohort"
          klass.where(context: campaignable)
        else
          klass.where(lecture: campaignable)
        end
      end

      def fetch_ids_from_scope(klass, scope)
        # Optimization: Use direct SQL join if the standard :members association exists.
        # This avoids N+1 queries on instances.
        if klass.reflect_on_association(:members)
          scope.joins(:members).pluck("users.id")
        else
          # Fallback: Load instances and use the Rosterable interface.
          # This is slower but guarantees correctness if the association name differs.
          scope.flat_map(&:allocated_user_ids)
        end
      end
  end
end
