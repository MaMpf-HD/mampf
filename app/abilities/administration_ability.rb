class AdministrationAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :exit, :profile, :search, :classification], :administration do
      user.admin?
    end
  end
end
