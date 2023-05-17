class ItemAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:create, :update, :edit, :destroy], Item do |item|
      (item.medium.nil? && !user.generic?) ||
        (item.medium && user.can_edit?(item.medium))
    end

    can :display, Item
  end
end
