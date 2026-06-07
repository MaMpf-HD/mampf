class RegistrationUserRegistrationAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :destroy, Registration::UserRegistration do |registration|
      user.can_edit?(registration.registration_campaign.campaignable)
    end

    can [:index, :create, :destroy, :add], Lecture do |lecture|
      student_registration_participant?(user, lecture)
    end
  end

  private

    def student_registration_participant?(user, lecture)
      lecture.visible_for_user?(user) &&
        lecture.in?(user.lectures) &&
        !user.in?(lecture.tutors) &&
        user != lecture.teacher &&
        !user.can_edit?(lecture)
    end
end
