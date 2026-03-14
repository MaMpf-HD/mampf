class RegistrationItemAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:read, :roster], Registration::Item do |item|
      user.can_edit?(item.registration_campaign.campaignable)
    end

    can [:create, :update, :destroy], Registration::Item do |item|
      user.can_edit?(item.registration_campaign.campaignable)
    end
  end
end
