class ProgramAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :edit, :update, :create, :destroy], Program do
      user.admin?
    end
  end
end