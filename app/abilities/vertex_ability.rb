class VertexAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create, :update, :destroy], :vertex do |quiz|
      user.can_edit?(quiz)
    end
  end
end
