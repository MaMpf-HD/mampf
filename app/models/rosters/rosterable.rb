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

      # Abstract method to add a user to the roster
      # @param user [User] the user to add
      # @param source_campaign [RegistrationCampaign] the campaign triggering the addition
      def add_user_to_roster!(user, source_campaign)
        raise(NotImplementedError, "#{self.class} must implement #add_user_to_roster!")
      end

      # Abstract method to remove a user from the roster
      # @param user [User] the user to remove
      def remove_user_from_roster!(user)
        raise(NotImplementedError, "#{self.class} must implement #remove_user_from_roster!")
      end

      # Override this method if the foreign key for the user in the roster entry is not :user_id
      def roster_user_id_column
        :user_id
      end
    end

    # Updates the roster based on the target list of users and the source campaign.
    # - Adds users from the list who are not currently in the roster.
    # - Removes users who are in the roster *via this campaign* but not in the list.
    # - Leaves manual entries (source_campaign_id: nil) or entries from other campaigns untouched.
    def materialize_allocation!(users, source_campaign)
      current_roster_user_ids = roster_entries.pluck(roster_user_id_column)
      target_user_ids = users.map(&:id)

      # Add users who are not in the roster at all
      users_to_add_ids = target_user_ids - current_roster_user_ids
      if users_to_add_ids.any?
        User.where(id: users_to_add_ids).find_each do |user|
          add_user_to_roster!(user, source_campaign)
        end
      end

      # Remove users who are in the roster via THIS campaign but not in the target list
      # We only touch entries that belong to this source_campaign.
      entries_to_remove = roster_entries.where(source_campaign: source_campaign)
                                        .where.not(roster_user_id_column => target_user_ids)

      entries_to_remove.destroy_all
    end
  end
end
