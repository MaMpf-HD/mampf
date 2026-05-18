class TermAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :edit, :update, :create, :destroy, :cancel,
         :set_active], Term do
      user.admin?
    end
  end
end
