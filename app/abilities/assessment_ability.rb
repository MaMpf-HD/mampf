class AssessmentAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :update], Lecture do |lecture|
      user.can_edit?(lecture)
    end

    can [:show, :update], Assessment::Assessment do |assessment|
      lecture = assessment.assessable&.lecture
      lecture.present? && user.can_edit?(lecture)
    end

    can :enter_points, Tutorial do |tutorial|
      user.admin? ||
        user.can_enter_points_in?(tutorial)
    end

    can :enter_points, Lecture do |lecture|
      user.admin? ||
        user.can_enter_points_in?(lecture)
    end
  end
end
