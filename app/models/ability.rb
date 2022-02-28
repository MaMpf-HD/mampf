# Ability class
# Class for defining access rights for admins, editors and normal users
# using the cancancan gem
class Ability
  # See the wiki for details:
  # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  include CanCan::Ability

  def initialize(user)
    # user ||= User.new
    # if user.admin?
    #   can :manage, :all
    # elsif user.editor? || user.teacher?
    #   can [:create, :show, :sanitize_params, :paginated_results,
    #        :filter_results, :add_to_watchlist, :new_watchlist], Watchlist

    #   can [:update, :destroy, :change_watchlist, :update_order, :change_visibility], Watchlist do |watchlist|
    #     watchlist.ownedBy(user)
    #   end

    #   can [:create], WatchlistEntry

    #   can [:destroy], WatchlistEntry do |watchlist_entry|
    #     watchlist_entry.ownedBy(user)
    #   end
    # else
    #   can [:create, :show, :sanitize_params, :paginated_results,
    #        :filter_results, :add_to_watchlist, :new_watchlist], Watchlist

    #   can [:update, :destroy, :change_watchlist, :update_order, :change_visibility], Watchlist do |watchlist|
    #     watchlist.ownedBy(user)
    #   end

    #   can [:create], WatchlistEntry

    #   can [:destroy], WatchlistEntry do |watchlist_entry|
    #     watchlist_entry.ownedBy(user)
    #   end
    # end
  end
end