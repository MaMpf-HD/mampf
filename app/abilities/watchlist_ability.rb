class WatchlistAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create, :show, :sanitize_params,
         :paginated_results, :filter_results, :add_to_watchlist,
         :new_watchlist, :change_watchlist, :update_order,
         :check_ownership], Watchlist

    can [:destroy, :edit, :update, :change_visibility], Watchlist do |watchlist|
      watchlist.ownedBy(user)
    end

  end
end