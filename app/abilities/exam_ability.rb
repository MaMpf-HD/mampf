class ExamAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :show, :create, :edit, :update, :destroy,
         :add_participant, :remove_participant], Exam do |exam|
      exam.lecture.present? && user.can_edit?(exam.lecture)
    end
  end
end
