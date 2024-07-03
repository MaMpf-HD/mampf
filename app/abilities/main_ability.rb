class MainAbility
  include CanCan::Ability

  def initialize(_user)
    can :start, :main
  end
end
