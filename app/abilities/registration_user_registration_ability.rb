class RegistrationUserRegistrationAbility
  include CanCan::Ability
  include StudentRegistrationParticipant

  def initialize(user)
    clear_aliased_actions

    can :destroy, Registration::UserRegistration do |registration|
      user.can_edit?(registration.registration_campaign.campaignable)
    end

    # Viewing a lecture's home page (its organizational front door) is open
    # to anyone who can find the lecture: students for published lectures,
    # and the lecture's staff at any time.
    can :index, Lecture do |lecture|
      lecture.published? || user.can_edit?(lecture) || user.admin
    end

    can [:create, :destroy, :add], Lecture do |lecture|
      student_registration_participant?(user, lecture)
    end
  end
end
