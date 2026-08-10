module Rosters
  # One roster lookup per lecture per rendered response. It lives on the view, not
  # on the controller: the view object spans the whole render, so every partial
  # shares the cache no matter which controller started it.
  module RosterCaching
    def roster_cache
      @roster_cache ||= { enabled: {}, tutorial: {} }
    end
  end
end
