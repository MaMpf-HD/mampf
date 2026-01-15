module Rosters
  # Standardizes roster management interfaces across models like Lectures, Tutorials and Talks.
  # Provides idempotent synchronization logic to update campaign-based assignments while preserving
  # manual entries.
  module Rosterable
    extend ActiveSupport::Concern

    # Models including this concern must:
    # - Have a `skip_campaigns` boolean column (default: false)
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

      validate :validate_skip_campaigns_switch
    end

    # Checks if the roster is currently locked for manual modifications.
    # A roster is locked if campaigns are NOT skipped AND a campaign is active (pending/running).
    # If skip_campaigns is true, it is never locked.
    # If skip_campaigns is false, it is unlocked only if no campaign is active.
    def locked?
      return false if skip_campaigns?

      # If in system mode, it is locked unless it was part of a completed campaign
      !campaign_completed?
    end

    # Checks if skip_campaigns can be enabled (switched from false to true).
    # This is only allowed if the item has never been part of a real (non-planning) campaign.
    def can_skip_campaigns?
      !in_real_campaign?
    end

    # Checks if skip_campaigns can be disabled (switched from true to false).
    # This is generally allowed as long as the roster is empty (to prevent data loss/inconsistency),
    # but since we enforce "once in campaign, always in campaign" via can_skip_campaigns?,
    # the reverse path is less critical but should still be safe.
    # For now, we allow it if the roster is empty.
    def can_unskip_campaigns?
      roster_empty?
    end

    # Checks if the roster is currently empty.
    def roster_empty?
      !roster_entries.exists?
    end

    # Checks if the item is associated with any campaign that materializes to rosters.
    # Tutorials and Talks always materialize. Cohorts only if propagate_to_lecture is true.
    def in_real_campaign?
      return false unless respond_to?(:registration_items)

      if association(:registration_items).loaded?
        registration_items.any?(&:materializes_to_roster?)
      else
        # Check if item is Tutorial or Talk (always materialize)
        tutorial_or_talk = registration_items
                           .exists?(registerable_type: ["Tutorial", "Talk"])

        return true if tutorial_or_talk

        # Check if item is Cohort with propagate_to_lecture = true
        registration_items
          .where(registerable_type: "Cohort")
          .joins("INNER JOIN cohorts ON cohorts.id = registration_items.registerable_id")
          .exists?("cohorts.propagate_to_lecture = true")
      end
    end

    # Checks if an active (non-completed) campaign exists for this item.
    def campaign_active?
      if association(:registration_items).loaded?
        registration_items.any? do |item|
          !item.registration_campaign.completed? && item.materializes_to_roster?
        end
      else
        # Tutorials and Talks in non-completed campaigns
        tutorial_or_talk = Registration::Campaign
                           .joins(:registration_items)
                           .where(registration_items: { registerable_id: id,
                                                        registerable_type: ["Tutorial", "Talk"] })
                           .where.not(status: :completed)
                           .exists?

        return true if tutorial_or_talk

        # Cohorts with propagate_to_lecture in non-completed campaigns
        Registration::Campaign
          .joins(:registration_items)
          .joins("INNER JOIN cohorts ON cohorts.id = registration_items.registerable_id")
          .where(registration_items: { registerable_id: id, registerable_type: "Cohort" })
          .where.not(status: :completed)
          .exists?("cohorts.propagate_to_lecture = true")
      end
    end

    # Checks if the item is associated with a completed campaign that materializes to rosters.
    def campaign_completed?
      if association(:registration_items).loaded?
        registration_items.any? do |item|
          item.registration_campaign.completed? && item.materializes_to_roster?
        end
      else
        # Tutorials and Talks in completed campaigns
        tutorial_or_talk = Registration::Campaign
                           .joins(:registration_items)
                           .where(registration_items: { registerable_id: id,
                                                        registerable_type: ["Tutorial", "Talk"] })
                           .exists?(status: :completed)

        return true if tutorial_or_talk

        # Cohorts with propagate_to_lecture in completed campaigns
        Registration::Campaign
          .joins(:registration_items)
          .joins("INNER JOIN cohorts ON cohorts.id = registration_items.registerable_id")
          .where(registration_items: { registerable_id: id, registerable_type: "Cohort" })
          .where(status: :completed)
          .exists?("cohorts.propagate_to_lecture = true")
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

    # Checks if the roster is over capacity.
    def over_capacity?
      return false unless respond_to?(:capacity)
      return false if capacity.nil?

      roster_entries.count > capacity
    end

    # Checks if the roster is full (reached or exceeded capacity).
    def full?
      return false unless respond_to?(:capacity)
      return false if capacity.nil?

      roster_entries.count >= capacity
    end

    # Returns the group type symbol for this rosterable (e.g. :tutorials, :talks).
    def roster_group_type
      self.class.name.tableize.to_sym
    end

    private

      def validate_skip_campaigns_switch
        return if new_record?
        return unless skip_campaigns_changed?

        if skip_campaigns?
          # Switching from false (Campaign Mode) to true (Skip Campaigns)
          # Only allowed if never in a real campaign
          errors.add(:base, I18n.t("roster.errors.campaign_associated")) if in_real_campaign?
        else
          # Switching from true (Skip Campaigns) to false (Campaign Mode)
          # Only allowed if roster is empty (to avoid data inconsistency)
          errors.add(:base, I18n.t("roster.errors.roster_not_empty")) unless roster_empty?
        end
      end
  end
end
