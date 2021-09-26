class EventAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:update_vertex_default], :event do
      !user.generic?
    end
  end
end