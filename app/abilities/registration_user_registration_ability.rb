class RegistrationUserRegistrationAbility
  include CanCan::Ability
  include StudentRegistrationParticipant

  def initialize(user)
    clear_aliased_actions

    can :destroy, Registration::UserRegistration do |registration|
      user.can_edit?(registration.registration_campaign.campaignable)
    end

    can [:index, :create, :destroy, :add], Lecture do |lecture|
      student_registration_participant?(user, lecture)
    end
  end
end
