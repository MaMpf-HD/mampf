class UserAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:delete_account, :teacher], User

    can [:index, :elevate, :destroy], User do
      user.admin?
    end

    can [:edit, :update], User do |given_user|
      user.admin? || (!user.generic? && user == given_user)
    end

    can [:fill_user_select, :list, :list_generic_users], User do
      !user.generic?
    end
  end
end