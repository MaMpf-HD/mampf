module Rosters
  module RosterCaching
    extend ActiveSupport::Concern

    included do
      helper_method :roster_cache
    end

    def roster_cache
      @roster_cache ||= { enabled: {}, tutorial: {} }
    end
  end
end
