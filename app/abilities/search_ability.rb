class SearchAbility
  include CanCan::Ability

  def initialize(_user)
    clear_aliased_actions

    can :index, :search
  end
end
