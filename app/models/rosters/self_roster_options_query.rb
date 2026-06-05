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
      filtered_rosterables = rosterables.each_with_index.select do |rosterable, _index|
        rosterable.config_allow_self_add? || rosterable.allow_self_remove?(@user)
      end

      filtered_rosterables.sort_by do |rosterable, index|
        [sort_priority(rosterable), index]
      end.map(&:first)
    end

    private

      def sort_priority(rosterable)
        return 0 if rosterable.allow_self_add?(@user)
        return 1 if rosterable.allow_self_remove?(@user)

        2
      end
  end
end
