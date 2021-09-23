class QuizAbility
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    clear_aliased_actions

    can [:take, :proceed, :new], Quiz

    can [:edit, :update, :destroy, :linearize, :set_root, :set_level,
         :update_default_target, :delete_edge], Quiz do |quiz|
      user.can_edit?(quiz.becomes(Medium))
    end
  end
end