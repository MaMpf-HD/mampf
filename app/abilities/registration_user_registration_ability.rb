class RegistrationUserRegistrationAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :destroy, Registration::UserRegistration do |registration|
      user.can_edit?(registration.registration_campaign.campaignable)
    end
  end
end
