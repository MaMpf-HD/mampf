class QuestionAbility
  include CanCan::Ability

  def initialize(user)
    can [:edit, :update, :set_solution_type, :reassign], Question do |question|
      user.can_edit?(question)
    end
  end
end