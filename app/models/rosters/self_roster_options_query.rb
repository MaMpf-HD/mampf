module Rosters
  class SelfRosterOptionsQuery
    Result = Struct.new(:rosterables)
    def initialize(lecture, user)
      @lecture = lecture
      @user = user
    end

    def call
      Result.new(lecture_rosterables)
    end

    def lecture_rosterables
      # get all rosterables for the lecture
      rosterables = []
      rosterables.concat(@lecture.talks)
      rosterables.concat(@lecture.tutorials)
      rosterables.concat(@lecture.cohorts)
      # show joinable rosterables and rosterables the user can still leave
      rosterables.select do |rosterable|
        rosterable.config_allow_self_add? || rosterable.allow_self_remove?(@user)
      end
    end
  end
end
