class WatchlistAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :add_medium], Watchlist

    can :show, Watchlist do |watchlist|
      watchlist.owned_by?(user) || watchlist.public
    end

    can [:create, :update, :destroy, :edit,
         :change_visibility], Watchlist do |watchlist|
      watchlist.owned_by?(user)
    end

    can :update_order, Watchlist do |watchlist, entries|
      watchlist.owned_by?(user) &&
        entries.all? { |entry| entry&.in?(watchlist.watchlist_entries) }
    end
  end
end
