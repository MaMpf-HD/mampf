class LessonAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :show, Lesson do |lesson|
      lesson.visible_for_user?(user)
    end

    can [:new, :edit, :update, :create, :destroy], Lesson do |lesson|
      user.can_edit?(lesson)
    end
  end
end