class DivisionAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:edit, :new, :update, :create, :destroy], Division do
      user.admin?
    end
  end
end
