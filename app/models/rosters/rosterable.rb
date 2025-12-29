module Rosters
  # Standardizes roster management interfaces across models like Lectures, Tutorials and Talks.
  # Provides idempotent synchronization logic to update campaign-based assignments while preserving
  # manual entries.
  module Rosterable
    extend ActiveSupport::Concern

    # Models including this concern must:
    # - Have a `managed_by_campaign` boolean column (default: true)
    # - Implement #roster_entries (returns ActiveRecord::Relation)

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

    # Checks if the roster is currently locked for manual modifications.
    # A roster is locked if it is marked as managed_by_campaign and no non-planning
    # campaign including this rosterable has been completed yet.
    def locked?
      return false unless managed_by_campaign?

      if association(:registration_items).loaded?
        registration_items.none? do |item|
          item.registration_campaign.completed? && !item.registration_campaign.planning_only?
        end
      else
        !Registration::Campaign
          .joins(:registration_items)
          .where(registration_items: { registerable_id: id, registerable_type: self.class.name })
          .exists?(status: :completed, planning_only: false)
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
    # - Adds users from the list who are not currently in the roster.
    # - Removes users who are in the roster *via this campaign* but not in the list.
    # - Leaves manual entries (source_campaign_id: nil) or entries from other campaigns untouched.
    def materialize_allocation!(user_ids:, campaign:)
      current_roster_user_ids = roster_entries.pluck(roster_user_id_column)
      target_user_ids = user_ids.uniq

      # Bulk Insert
      # We use insert_all to avoid N+1 inserts. This skips callbacks, which is acceptable
      # for bulk allocations where we just want to sync the state.
      users_to_add_ids = target_user_ids - current_roster_user_ids
      if users_to_add_ids.any?
        # insert_all does not automatically apply the association scope (e.g. foreign keys).
        # We must explicitly merge the scope attributes (like { tutorial_id: 123 }).
        scope_attrs = roster_entries.scope_attributes

        attributes = users_to_add_ids.map do |uid|
          {
            roster_user_id_column => uid,
            :source_campaign_id => campaign.id,
            :created_at => Time.current,
            :updated_at => Time.current
          }.merge(scope_attrs)
        end
        # insert_all on the association automatically scopes to the parent (e.g. tutorial_id)
        roster_entries.insert_all(attributes) # rubocop:disable Rails/SkipsModelValidations
      end

      # Bulk Delete
      # Remove users who are in the roster via THIS campaign but not in the target list
      # We use delete_all to avoid instantiating objects.
      entries_to_remove = roster_entries.where(source_campaign: campaign)
                                        .where.not(roster_user_id_column => target_user_ids)

      entries_to_remove.delete_all
    end
  end
end
