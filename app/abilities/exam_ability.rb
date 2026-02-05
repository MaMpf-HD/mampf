class ExamAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :create, :edit, :update, :destroy], Exam do |exam|
      exam.lecture.present? && user.can_edit?(exam.lecture)
    end
  end
end
