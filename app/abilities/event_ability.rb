class EventAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

  end
end