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
      # filter rosterables that allow self add or self remove
      rosterables.select do |rosterable|
        rosterable.config_allow_self_add? || rosterable.config_allow_self_remove?
      end
    end
  end
end
