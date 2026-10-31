module Rosters
  class SelfMaterializationService
    class RosterLockedError < StandardError; end
    class RosterFullError < StandardError; end
    class SelfAddNotAllowedError < StandardError; end
    class SelfRemoveNotAllowedError < StandardError; end
    class LectureHasOtherRosterEntryError < StandardError; end
    class LastGroupError < StandardError; end

    def initialize(rosterable, user)
      @rosterable = rosterable
      @user = user
    end

    def self_add!
      ensure_rosterable_unlocked!
      ensure_rosterable_not_full!
      ensure_rosterable_allow_self_add!
      Rosters::MaintenanceService.new.add_user!(@user, @rosterable, ignore_capacity: false)
    end

    # Refuses to let an enrolled student leave their last group; they can only
    # leave the lecture as a whole. Locks the campaigns, then the group, then
    # the lecture, like MaintenanceService#remove_user!. Without the lecture's
    # lock, two browser tabs could each leave a different group, each assuming
    # the other one remains, and the student would end up with none.
    def self_remove!
      ActiveRecord::Base.transaction do
        lecture = @rosterable.lecture
        if lecture && @rosterable.enrolls_in_lecture?
          Rosters::UserPlaces.new(@user).lock_campaigns!([lecture])
        end
        @rosterable.lock!
        lecture&.lock!
        ensure_rosterable_unlocked!
        ensure_rosterable_allow_self_remove!
        ensure_not_last_group!
        Rosters::MaintenanceService.new.remove_user!(@user, @rosterable)
      end
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

        Rosters::MaintenanceService.new.move_user!(@user, from, @rosterable, ignore_capacity: false)
      end
    end

    private

      def ensure_not_last_group!
        lecture = @rosterable.lecture
        return unless lecture

        raise(LastGroupError) if Rosters::LectureLeave.new(lecture, @user).only_place?(@rosterable)
      end

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
