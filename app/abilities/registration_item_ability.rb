class RegistrationItemAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:read, :roster, :update, :destroy,
         :destroy_with_registerable], Registration::Item do |item|
      user.can_edit?(item.registration_campaign.campaignable)
    end

    # See Registration::Campaign#accepts_new_items? for when a group may join.
    can :create, Registration::Item do |item|
      campaign = item.registration_campaign
      user.can_edit?(campaign.campaignable) && campaign.accepts_new_items?
    end
  end
end
