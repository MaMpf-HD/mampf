class QuestionAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:edit, :update, :set_solution_type, :reassign,
         :cancel_question_basics], Question do |question|
      user.can_edit?(question)
    end
  end
end