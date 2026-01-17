module Rosters
  # Standardizes roster management interfaces across models like Lectures, Tutorials and Talks.
  # Provides idempotent synchronization logic to update campaign-based assignments while preserving
  # manual entries.
  module Rosterable
    extend ActiveSupport::Concern

    TYPES = ["Tutorial", "Talk", "Cohort", "Lecture"].freeze

    # Models including this concern must:
    # - Implement #roster_entries (returns ActiveRecord::Relation)
    #
    # Models that are also Registerable should additionally:
    # - Have a `skip_campaigns` boolean column (default: false)
    #   (This allows switching between campaign-managed and manual roster management)

    included do
      # Abstract method to retrieve the roster entries (e.g., memberships or joins)
      # Should return an ActiveRecord::Relation
      def roster_entries
        raise(NotImplementedError, "#{self.class} must implement #roster_entries")
      end

      # Override this method if the foreign key for the user in the roster entry is not :user_id
      def roster_user_id_column
        :user_id
      end

      # Override this method if the association name doesn't follow the pattern
      # #{model_name}_memberships (e.g., Talk uses :speaker_talk_joins)
      def roster_association_name
        :"#{self.class.name.underscore}_memberships"
      end

      validate :validate_skip_campaigns_switch
      before_destroy :enforce_rosterable_destruction_constraints, prepend: true
    end

    # Checks if the item can be safely destroyed.
    def destructible?
      !in_campaign? && roster_empty?
    end

    # Checks if the roster is locked for manual modifications.
    # Models without skip_campaigns (e.g., Lecture) are never locked.
    # A roster is locked if campaigns are NOT skipped AND no campaign
    # has been completed yet.
    def locked?
      return false unless respond_to?(:skip_campaigns)
      return false if skip_campaigns?

      !in_completed_campaign?
    end

    # Checks if skip_campaigns can be enabled (switched from false to true).
    # This is only allowed if the item has never been part of any campaign.
    # Models without skip_campaigns always return false.
    def can_skip_campaigns?
      return false unless respond_to?(:skip_campaigns)

      !in_campaign?
    end

    # Checks if skip_campaigns can be disabled (switched from true to false).
    # This is generally allowed as long as the roster is empty (to prevent data loss/inconsistency),
    # but since we enforce "once in campaign, always in campaign" via can_skip_campaigns?,
    # the reverse path is less critical but should still be safe.
    # For now, we allow it if the roster is empty.
    # Models without skip_campaigns always return false.
    def can_unskip_campaigns?
      return false unless respond_to?(:skip_campaigns)

      roster_empty?
    end

    # Checks if the roster is currently empty.
    def roster_entries_count
      association_name = roster_association_name

      if association_name && association(association_name).loaded?
        public_send(association_name).size
      else
        roster_entries.count
      end
    end

    def roster_empty?
      association_name = roster_association_name

      if association_name && association(association_name).loaded?
        public_send(association_name).empty?
      else
        !roster_entries.exists?
      end
    end

    # Checks if the item is associated with any campaign.
    def in_campaign?
      return false unless respond_to?(:registration_items)

      return @in_campaign if defined?(@in_campaign)

      @in_campaign = registration_items.exists?
    end

    # Checks if the item is associated with a completed campaign.
    def in_completed_campaign?
      return false unless respond_to?(:registration_items)

      return @in_completed_campaign if defined?(@in_completed_campaign)

      @in_completed_campaign = Registration::Campaign
                               .joins(:registration_items)
                               .where(registration_items: { registerable_id: id,
                                                            registerable_type: self.class.name })
                               .exists?(status: :completed)
    end

    # Returns the IDs of users currently in the roster.
    # Required by the Registration::Registerable concern.
    def allocated_user_ids
      if roster_entries.loaded?
        roster_entries.map { |e| e.public_send(roster_user_id_column) }
      else
        roster_entries.pluck(roster_user_id_column)
      end
    end

    # Adds a single user to the roster.
    # Can be overridden by the model if custom logic/callbacks are needed.
    def add_user_to_roster!(user, source_campaign = nil)
      roster_entries.create!(
        roster_user_id_column => user.id,
        :source_campaign => source_campaign
      )
    end

    # Removes a single user from the roster.
    # Can be overridden by the model if custom logic/callbacks are needed.
    def remove_user_from_roster!(user)
      roster_entries.find_by(roster_user_id_column => user.id)&.destroy
    end

    # Updates the roster based on the target list of users and the source campaign.
    # - Synchronizes the local roster (bulk adds/removes users for this campaign).
    # - Propagates new members to the parent lecture roster (if applicable).
    def materialize_allocation!(user_ids:, campaign:)
      transaction do
        current_ids = roster_entries.pluck(roster_user_id_column)
        target_ids = user_ids.uniq

        add_missing_users!(target_ids, current_ids, campaign)
        remove_excess_users!(target_ids, campaign)
        propagate_to_lecture!(target_ids)
      end
    end

    def propagate_to_lecture!(user_ids)
      return if user_ids.empty?

      return if is_a?(Cohort) && !propagate_to_lecture

      return unless respond_to?(:lecture)

      parent = lecture
      return unless parent.is_a?(Lecture)
      return if parent == self

      parent.ensure_roster_membership!(user_ids)
    end

    # Identifies users in the target list who are not yet in the roster and
    # performs a bulk insert to add them efficiently, associating them with
    # the given campaign.
    def add_missing_users!(target_ids, current_ids, campaign)
      users_to_add = target_ids - current_ids
      return if users_to_add.empty?

      # insert_all does not automatically apply the association scope (e.g. foreign keys).
      # We must explicitly merge the scope attributes (like { tutorial_id: 123 }).
      scope_attrs = roster_entries.scope_attributes

      attributes = users_to_add.map do |uid|
        {
          roster_user_id_column => uid,
          :source_campaign_id => campaign.id,
          :created_at => Time.current,
          :updated_at => Time.current
        }.merge(scope_attrs)
      end
      roster_entries.insert_all(attributes) # rubocop:disable Rails/SkipsModelValidations
    end

    # Identifies users currently in the roster associated with this specific
    # campaign but not in the target list, and removes them. This cleans up
    # allocations from the same campaign that are no longer valid,
    # without touching members added manually or by other campaigns.
    def remove_excess_users!(target_ids, campaign)
      roster_entries.where(source_campaign: campaign)
                    .where.not(roster_user_id_column => target_ids)
                    .delete_all
    end

    # Checks if the roster is over capacity.
    def over_capacity?
      return false unless respond_to?(:capacity)
      return false if capacity.nil?

      roster_entries_count > capacity
    end

    # Checks if the roster is full (reached or exceeded capacity).
    def full?
      return false unless respond_to?(:capacity)
      return false if capacity.nil?

      roster_entries_count >= capacity
    end

    # Returns the group type symbol for this rosterable (e.g. :tutorials, :talks).
    def roster_group_type
      self.class.name.tableize.to_sym
    end

    private

      def validate_skip_campaigns_switch
        return unless respond_to?(:skip_campaigns)
        return if new_record?
        return unless skip_campaigns_changed?

        if skip_campaigns?
          # Switching from false (Campaign Mode) to true (Skip Campaigns)
          # Only allowed if never in any campaign
          errors.add(:base, I18n.t("roster.errors.campaign_associated")) if in_campaign?
        else
          # Switching from true (Skip Campaigns) to false (Campaign Mode)
          # Only allowed if roster is empty (to avoid data inconsistency)
          errors.add(:base, I18n.t("roster.errors.roster_not_empty")) unless roster_empty?
        end
      end

      def enforce_rosterable_destruction_constraints
        if in_campaign?
          errors.add(:base, I18n.t("roster.errors.cannot_delete_in_campaign"))
          throw(:abort)
        end

        return if roster_empty?

        errors.add(:base, I18n.t("roster.errors.cannot_delete_not_empty"))
        throw(:abort)
      end
  end
end
