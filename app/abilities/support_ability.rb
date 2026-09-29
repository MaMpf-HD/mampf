class SupportAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    return unless user.support? || user.admin?

    can :index, :support

    # An admin's account is beyond the support's reach; their own is not.
    can [:edit, :update, :unlock, :password_reset, :confirmation], User do |person|
      user.admin? || !person.admin?
    end

    can :assign_support, User if user.admin?
  end
end
