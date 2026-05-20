class AdministrationAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :exit, :profile, :search], :administration do
      !user.generic?
    end

    can :classification, :administration do
      user.admin?
    end

    can :csp_violation_reports, :administration do
      user.admin?
    end
  end
end
