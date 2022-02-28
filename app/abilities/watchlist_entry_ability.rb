class WatchlistEntryAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:create], WatchlistEntry

    can [:destroy], WatchlistEntry do |watchlist_entry|
      watchlist_entry.watchlist.owned_by?(user)
    end
  end
end
