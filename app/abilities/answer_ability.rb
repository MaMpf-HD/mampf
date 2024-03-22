class AnswerAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create, :update, :destroy, :cancel_edit], Answer do |answer|
      answer.question.present? && user.can_edit?(answer.question)
    end
  end
end
