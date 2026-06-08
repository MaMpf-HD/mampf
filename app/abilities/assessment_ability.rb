class AssessmentAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :index, Lecture do |lecture|
      user.can_edit?(lecture)
    end

    can [:show, :update], Assessment::Assessment do |assessment|
      lecture = assessment.assessable&.lecture
      lecture.present? && user.can_edit?(lecture)
    end

    can :grade, Tutorial do |tutorial|
      user.tutor_in?(tutorial) || user.can_edit_teachables?
    end
  end
end
