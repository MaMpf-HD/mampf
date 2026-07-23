module Rosters
  class SelfRosterAvailability
    def initialize(lecture, user)
      @lecture = lecture
      @user = user
    end

    # A membership only blocks new registration if joining a new slot would
    # require leaving it — i.e. it belongs to a roster-exclusive pool
    # (tutorials). Non-exclusive memberships (e.g. an interest cohort or a
    # talk) can coexist with any new registration and never block it.
    def blocked_by_unremovable_assignment?
      rosterized_entries.any? do |rosterable|
        rosterable.roster_exclusive_within_lecture? &&
          rosterable.user_allocated?(@user) &&
          !rosterable.config_allow_self_remove?
      end
    end

    private

      def rosterized_entries
        @rosterized_entries ||= Array(
          StudentMaterializedResultResolver.new(@user)
                                           .all_rosterized_for_lecture(@lecture)
        )
      end
  end
end
