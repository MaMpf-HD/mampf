class RegistrationUserRegistrationAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :destroy, Registration::UserRegistration do |registration|
      user.can_edit?(registration.registration_campaign.campaignable)
    end

    can [:index, :create, :destroy, :add], Lecture do |lecture|
      !user.in?(lecture.tutors) && (user != lecture.teacher) && !user.can_edit?(lecture)
    end
  end
end
