module Rosters
  class SelfRosterOptionsQuery
    def initialize(lecture, user)
      @lecture = lecture
      @user = user
    end

    def call
      # The lecture home page asks this for whoever opens it, staff included.
      return [] unless Registration::Participation.allowed?(@user, @lecture)

      # get all rosterables for the lecture
      rosterables = []
      rosterables.concat(@lecture.talks)
      rosterables.concat(@lecture.tutorials)
      rosterables.concat(@lecture.cohorts)

      # show joinable rosterables and rosterables the user can still leave,
      # in the lecture's order: talks by position, tutorials by title
      rosterables.select do |rosterable|
        rosterable.config_allow_self_add? || rosterable.allow_self_remove?(@user)
      end
    end
  end
end
