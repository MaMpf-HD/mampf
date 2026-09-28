class SupportAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :edit, :update], :support if user.support? || user.admin?
  end
end
