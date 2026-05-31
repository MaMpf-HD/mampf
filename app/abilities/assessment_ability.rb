class AssessmentAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    alias_action(:update_team_multi,
                 :update_team,
                 :update_user,
                 :refresh_submission,
                 :refresh_user,
                 :mark_as_participated,
                 to: :grade)

    can :index, Lecture do |lecture|
      user.can_edit?(lecture)
    end

    can [:show, :update], Assessment::Assessment do |assessment|
      lecture = assessment.assessable&.lecture
      lecture.present? && user.can_edit?(lecture)
    end

    can :grade, Assessment::Assessment do |assessment|
      lecture = assessment.assessable&.lecture
      lecture.present? && user.can_edit?(lecture)
    end
  end
end
