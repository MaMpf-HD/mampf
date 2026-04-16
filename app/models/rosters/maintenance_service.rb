module Rosters
  class UserAlreadyInBundleError < StandardError
    attr_reader :conflicting_group

    def initialize(conflicting_group)
      @conflicting_group = conflicting_group
      super
    end
  end

  class MaintenanceService
    # Manages manual roster operations (add, remove, move) while enforcing capacity
    # constraints and ensuring transactional integrity
    class CapacityExceededError < StandardError; end

    def add_user!(user, rosterable, force: false)
      rosterable.with_lock do
        add_user_without_lock!(user, rosterable, force: force)
      end
    end

    def remove_user!(user, rosterable)
      rosterable.with_lock do
        remove_user_without_lock!(user, rosterable)
      end
    end

    def move_user!(user, from_rosterable, to_rosterable, force: false)
      lock_rosterables_in_order(from_rosterable, to_rosterable) do
        remove_user_without_lock!(user, from_rosterable)
        add_user_without_lock!(user, to_rosterable, force: force)
      end
    end

    private

      def user_in_roster?(user, rosterable)
        rosterable.roster_entries.exists?(rosterable.roster_user_id_column => user.id)
      end

      def add_user_without_lock!(user, rosterable, force: false)
        return if user_in_roster?(user, rosterable)

        ensure_uniqueness!(user, rosterable)

        unless force || within_capacity?(rosterable)
          raise(CapacityExceededError,
                "Capacity exceeded for #{rosterable.class.name} #{rosterable.id}")
        end

        rosterable.add_user_to_roster!(user)
        propagate_to_lecture!(user, rosterable)
        update_registration_materialization(user, rosterable)
      end

      def remove_user_without_lock!(user, rosterable)
        rosterable.remove_user_from_roster!(user)
        cascade_removal_from_subgroups!(user, rosterable)
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
          return
        end

        sorted_rosterables[index].with_lock do
          lock_rosterables_recursively(sorted_rosterables, index + 1, &)
        end
      end

      def within_capacity?(rosterable)
        return true unless rosterable.respond_to?(:capacity)
        return true if rosterable.capacity.nil?

        rosterable.roster_entries.count < rosterable.capacity
      end

      def update_registration_materialization(user, rosterable)
        Registration::Item.where(registerable: rosterable).find_each do |item|
          # rubocop:disable Rails/SkipsModelValidations
          item.user_registrations.where(user: user)
              .update_all(materialized_at: Time.current)
          # rubocop:enable Rails/SkipsModelValidations
        end
      end

      def ensure_uniqueness!(user, rosterable)
        return unless rosterable.is_a?(Tutorial)

        membership = TutorialMembership
                     .where(lecture_id: rosterable.lecture_id, user_id: user.id)
                     .where.not(tutorial_id: rosterable.id)
                     .first

        return unless membership

        raise(UserAlreadyInBundleError, membership.tutorial)
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
