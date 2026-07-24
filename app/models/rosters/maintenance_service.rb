module Rosters
  class MaintenanceService
    # Manages manual roster operations (add, remove, move) while enforcing capacity
    # constraints and ensuring transactional integrity
    class CapacityExceededError < StandardError; end

    def add_user!(user, rosterable, force: false, source_campaign_id: nil)
      added = rosterable.with_lock do
        add_user_without_lock!(user,
                               rosterable,
                               force: force,
                               source_campaign_id: source_campaign_id)
      end
      RosterNotificationMailer.added(user, rosterable) if added
      added
    end

    def remove_user!(user, rosterable)
      removed = rosterable.with_lock do
        remove_user_without_lock!(user, rosterable)
      end
      RosterNotificationMailer.removed(user, rosterable) if removed
      removed
    end

    def move_user!(user, from_rosterable, to_rosterable, force: false)
      return if from_rosterable == to_rosterable

      moved = lock_rosterables_in_order(from_rosterable, to_rosterable) do
        raise(ActiveRecord::Rollback) unless user_in_roster?(user, from_rosterable)

        removed = remove_user_without_lock!(user, from_rosterable)
        added   = add_user_without_lock!(user, to_rosterable, force: force)

        raise(ActiveRecord::Rollback) unless removed && added

        true
      end
      RosterNotificationMailer.moved(user, from_rosterable, to_rosterable) if moved
      moved
    end

    private

      def user_in_roster?(user, rosterable)
        rosterable.roster_entries.exists?(rosterable.roster_user_id_column => user.id)
      end

      def add_user_without_lock!(user, rosterable, force: false, source_campaign_id: nil)
        return if user_in_roster?(user, rosterable)

        ensure_uniqueness!(user, rosterable)

        unless force || within_capacity?(rosterable)
          raise(CapacityExceededError,
                "Capacity exceeded for #{rosterable.class.name} #{rosterable.id}")
        end

        membership = rosterable.add_user_to_roster!(user)
        propagate_to_lecture!(user, rosterable)
        update_registration_materialization(user,
                                            rosterable,
                                            source_campaign_id: source_campaign_id)
        membership
      end

      def remove_user_without_lock!(user, rosterable)
        removed = rosterable.remove_user_from_roster!(user)
        cascade_removal_from_subgroups!(user, rosterable)
        removed
      end

      def lock_rosterables_in_order(*rosterables, &)
        ActiveRecord::Base.transaction do
          sorted_rosterables = rosterables.uniq.sort_by { |r| [r.class.name, r.id.to_i] }
          lock_rosterables_recursively(sorted_rosterables, 0, &)
        end
      end

      def lock_rosterables_recursively(sorted_rosterables, index, &)
        if index >= sorted_rosterables.length
          yield
        else
          sorted_rosterables[index].with_lock do
            lock_rosterables_recursively(sorted_rosterables, index + 1, &)
          end
        end
      end

      def within_capacity?(rosterable)
        return true unless rosterable.respond_to?(:capacity)
        return true if rosterable.capacity.nil?

        rosterable.roster_entries.count < rosterable.capacity
      end

      def update_registration_materialization(user, rosterable, source_campaign_id: nil)
        now = Time.current

        Registration::Item.where(registerable: rosterable).find_each do |item|
          # rubocop:disable Rails/SkipsModelValidations
          item.user_registrations.where(user: user)
              .update_all(materialized_at: now)
          # rubocop:enable Rails/SkipsModelValidations
        end

        return if source_campaign_id.blank?

        # rubocop:disable Rails/SkipsModelValidations
        Registration::UserRegistration.rejected
                                      .where(user: user,
                                             registration_campaign_id: source_campaign_id,
                                             rejection_overridden_at: nil)
                                      .update_all(rejection_overridden_at: now,
                                                  updated_at: now)
        # rubocop:enable Rails/SkipsModelValidations
      end

      def ensure_uniqueness!(user, rosterable)
        conflicting = rosterable.conflicting_lecture_membership(user)
        return unless conflicting

        raise(UserAlreadyInBundleError, conflicting)
      end

      def propagate_to_lecture!(user, rosterable)
        return if rosterable.is_a?(Cohort) && !rosterable.propagate_to_lecture?
        return unless rosterable.respond_to?(:lecture)

        lecture = rosterable.lecture
        return unless lecture.is_a?(Lecture)
        return if lecture == rosterable

        lecture.ensure_roster_membership!([user.id])
      end

      def cascade_removal_from_subgroups!(user, rosterable)
        return unless rosterable.is_a?(Lecture)

        rosterable.tutorials.find_each do |tutorial|
          tutorial.remove_user_from_roster!(user)
        end

        rosterable.talks.find_each do |talk|
          talk.remove_user_from_roster!(user)
        end

        rosterable.cohorts.find_each do |cohort|
          next unless cohort.propagate_to_lecture?

          cohort.remove_user_from_roster!(user)
        end
      end
  end
end
