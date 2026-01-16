module Rosters
  class MaintenanceService
    # Manages manual roster operations (add, remove, move) while enforcing capacity
    # constraints and ensuring transactional integrity
    class CapacityExceededError < StandardError; end

    def add_user!(user, rosterable, force: false)
      return if user_in_roster?(user, rosterable)

      unless force || within_capacity?(rosterable)
        raise(CapacityExceededError,
              "Capacity exceeded for #{rosterable.class.name} #{rosterable.id}")
      end

      rosterable.add_user_to_roster!(user)
      update_registration_materialization(user, rosterable)
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

      def update_registration_materialization(user, rosterable)
        Registration::Item.where(registerable: rosterable).find_each do |item|
          # rubocop:disable Rails/SkipsModelValidations
          item.user_registrations.where(user: user)
              .update_all(materialized_at: Time.current)
          # rubocop:enable Rails/SkipsModelValidations
        end
      end
  end
end
