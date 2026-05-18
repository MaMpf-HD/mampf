class QuestionAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:edit, :update, :set_solution_type, :reassign,
         :cancel_question_basics, :cancel_solution_edit,
         :render_question_parameters], Question do |question|
      user.can_edit?(question)
    end
  end
end
