class WatchlistEntryAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create], WatchlistEntry

    can [:destroy], WatchlistEntry do |watchlist_entry|
      watchlist_entry.watchlist.ownedBy(user)
    end
  end
end