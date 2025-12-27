class RegistrationItemAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:create, :update, :destroy], Registration::Item do |item|
      user.can_edit?(item.registration_campaign.campaignable)
    end
  end
end
