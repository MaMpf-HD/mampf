class SubjectAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :edit, :update, :create, :destroy], Subject do
      user.admin?
    end
  end
end
