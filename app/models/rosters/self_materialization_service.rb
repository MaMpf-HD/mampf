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
