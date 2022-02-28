class WatchlistAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions
    user ||= User.new

    can [:index, :new, :add_to_watchlist], Watchlist do |watchlist|
      user.persisted?
    end

    can :show, Watchlist do |watchlist|
      watchlist.owned_by?(user) || watchlist.public
    end

    can [:create, :update, :destroy, :edit, :update_order,
         :change_visibility, :add_to_watchlist], Watchlist do |watchlist|
      watchlist.owned_by?(user)
    end
  end
end