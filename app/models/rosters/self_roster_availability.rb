module Rosters
  class SelfRosterAvailability
    def initialize(lecture, user)
      @lecture = lecture
      @user = user
    end

    def blocked_by_unremovable_assignment?
      rosterized_entries.any? do |rosterable|
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
