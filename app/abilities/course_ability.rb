class CourseAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:create, :destroy], Course do
      user.admin?
    end

    can [:edit, :update], Course do |course|
      user.can_edit?(course)
    end

    can [:search], Course do
      !user.generic?
    end

    can [:render_question_counter, :take_random_quiz], Course do |course|
      !user.generic? || course.subscribed_by?(user)
    end
  end
end