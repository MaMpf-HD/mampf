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

    can :grade, Lecture do |lecture|
      user.admin? ||
        user.can_grade_in_scope?(lecture)
    end
  end
end
