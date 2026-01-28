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
      send_added_notification_email(user, rosterable)
      propagate_to_lecture!(user, rosterable)
      update_registration_materialization(user, rosterable)
    end

    def remove_user!(user, rosterable)
      rosterable.remove_user_from_roster!(user)
      send_removed_notification_email
      cascade_removal_from_subgroups!(user, rosterable)
    end

    def move_user!(user, from_rosterable, to_rosterable, force: false)
      ActiveRecord::Base.transaction do
        remove_user!(user, from_rosterable)
        add_user!(user, to_rosterable, force: force)
      end
      send_moved_between_groups_notification_email(user, from_rosterable, to_rosterable)
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

      def ensure_uniqueness!(user, rosterable)
        return unless rosterable.is_a?(Tutorial)

        siblings = rosterable.lecture.tutorials.where.not(id: rosterable.id)
        membership = TutorialMembership.where(tutorial: siblings, user: user).first

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

      # TODO: consider make this shorter
      def send_added_notification_email(user, rosterable)
        RosterNotificationMailer.with(
          rosterable: rosterable,
          recipient: user,
          sender: DefaultSetting::PROJECT_EMAIL
        ).added_to_group_email.deliver_now
      end

      def send_removed_notification_email(user, rosterable)
        RosterNotificationMailer.with(
          rosterable: rosterable,
          recipient: user,
          sender: DefaultSetting::PROJECT_EMAIL
        ).removed_from_group_email.deliver_now
      end

      def send_moved_between_groups_notification_email(user, old_rosterable, new_rosterable)
        RosterNotificationMailer.with(
          old_rosterable: old_rosterable,
          new_rosterable: new_rosterable,
          recipient: user,
          sender: DefaultSetting::PROJECT_EMAIL
        ).moved_between_groups_email.deliver_now
      end
  end
end
