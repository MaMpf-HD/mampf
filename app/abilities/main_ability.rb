class MainAbility
  include CanCan::Ability

  def initialize(user)
    can :start, :main
  end
end