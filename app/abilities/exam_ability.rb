class ExamAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions
    return unless user

    can [:index, :new, :show, :create, :edit, :update, :destroy], Exam do |exam|
      exam.lecture.present? && user.can_edit?(exam.lecture)
    end
  end
end