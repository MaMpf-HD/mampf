class UserAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:delete_account, :teacher], User

    can [:index, :elevate, :destroy, :edit], User do
      user.admin?
    end

    can :update, User do |given_user|
      user.admin? || (!user.generic? && user == given_user)
    end

    can :fill_user_select, User do
      user.active_teachable_editor?
    end

    can :list_generic_users, User do
      user.admin?
    end
  end
end
