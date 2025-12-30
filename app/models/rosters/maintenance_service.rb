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
      return if user_in_roster?(user, rosterable)

      ensure_uniqueness!(user, rosterable)

      unless force || within_capacity?(rosterable)
        raise(CapacityExceededError,
              "Capacity exceeded for #{rosterable.class.name} #{rosterable.id}")
      end

      rosterable.add_user_to_roster!(user)
    end

    def remove_user!(user, rosterable)
      rosterable.remove_user_from_roster!(user)
    end

    def move_user!(user, from_rosterable, to_rosterable, force: false)
      ActiveRecord::Base.transaction do
        remove_user!(user, from_rosterable)
        add_user!(user, to_rosterable, force: force)
      end
    end

    private

      def user_in_roster?(user, rosterable)
        rosterable.roster_entries.exists?(rosterable.roster_user_id_column => user.id)
      end

      def within_capacity?(rosterable)
        return true unless rosterable.respond_to?(:capacity)
        return true if rosterable.capacity.nil?

        rosterable.roster_entries.count < rosterable.capacity
      end

      def ensure_uniqueness!(user, rosterable)
        return unless rosterable.is_a?(Tutorial)

        siblings = rosterable.lecture.tutorials.where.not(id: rosterable.id)
        membership = TutorialMembership.where(tutorial: siblings, user: user).first

        return unless membership

        raise(UserAlreadyInBundleError, membership.tutorial)
      end
  end
end
