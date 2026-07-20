class UserAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:delete_account, :teacher], User

    # Profile images are a teacher-profile feature: teacher images are shown to
    # everyone on the teacher info page, but a user's image must not be
    # enumerable across accounts. (Upload is gated separately in
    # UploadEndpointAuthorization.)
    can :image, User do |given_user|
      user&.admin? || user == given_user || given_user.teacher?
    end

    can [:index, :elevate, :destroy, :edit], User do
      user.admin?
    end

    can :update, User do |given_user|
      user.admin? || (!user.generic? && user == given_user)
    end

    can [:fill_user_select, :list_generic_users], User do
      user.admin?
    end
  end
end
