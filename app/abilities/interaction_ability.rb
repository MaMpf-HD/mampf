class InteractionAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :export_interactions, :export_probes], Interaction do
      user.admin?
    end
  end
end
