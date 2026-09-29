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

    return unless user.admin?

    can :assign_support, User

    # Nobody takes their own admin rights, so the last admin cannot lock all out.
    can :assign_admin, User do |person|
      person != user
    end

    # Staff accounts hold lectures, courses and media; only other accounts go.
    can :destroy, User do |person|
      person.generic? && person != user
    end
  end
end
