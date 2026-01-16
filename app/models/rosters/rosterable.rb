module Rosters
  # Standardizes roster management interfaces across models like Lectures, Tutorials and Talks.
  # Provides idempotent synchronization logic to update campaign-based assignments while preserving
  # manual entries.
  module Rosterable
    extend ActiveSupport::Concern

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
    end

    # Returns the IDs of users currently in the roster.
    # Required by the Registration::Registerable concern.
    def allocated_user_ids
      roster_entries.pluck(roster_user_id_column)
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

    private

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
  end
end
