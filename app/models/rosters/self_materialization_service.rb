module Rosters
  class SelfMaterializationService
    class RosterLockedError < StandardError; end
    class RosterFullError < StandardError; end
    class SelfAddNotAllowedError < StandardError; end
    class SelfRemoveNotAllowedError < StandardError; end
    class LectureHasOtherRosterEntryError < StandardError; end

    def initialize(rosterable, user)
      @rosterable = rosterable
      @user = user
    end

    def self_add!
      ensure_rosterable_unlocked!
      ensure_rosterable_not_full!
      ensure_rosterable_allow_self_add!
      Rosters::MaintenanceService.new.add_user!(@user, @rosterable, force: false)
    end

    def self_remove!
      ensure_rosterable_unlocked!
      ensure_rosterable_allow_self_remove!
      Rosters::MaintenanceService.new.remove_user!(@user, @rosterable)
    end

    # Leaves `from` for this rosterable in one step, so the old place is kept
    # when the new one cannot be taken. The checks run under both locks, in the
    # order MaintenanceService takes them: a lecturer who closes either group in
    # the meantime is seen before anybody moves.
    def self_switch!(from)
      ActiveRecord::Base.transaction do
        [from, @rosterable].sort_by { |r| [r.class.name, r.id.to_i] }.each(&:lock!)
        ensure_rosterable_unlocked!
        ensure_rosterable_not_full!
        ensure_rosterable_allow_self_add!
        raise(RosterLockedError) if from.locked?
        raise(SelfRemoveNotAllowedError) unless from.allow_self_remove?(@user)

        Rosters::MaintenanceService.new.move_user!(@user, from, @rosterable, force: false)
      end
    end

    private

      def ensure_rosterable_unlocked!
        raise(RosterLockedError) if @rosterable.locked?
      end

      def ensure_rosterable_not_full!
        raise(RosterFullError) if @rosterable.full?
      end

      def ensure_rosterable_allow_self_add!
        raise(SelfAddNotAllowedError) unless @rosterable.config_allow_self_add?
      end

      def ensure_rosterable_allow_self_remove!
        raise(SelfRemoveNotAllowedError) unless @rosterable.config_allow_self_remove?
      end
  end
end
