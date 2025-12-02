class CampaignAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :create, :show, :edit, :update, :destroy, :open, :close, :reopen],
        Registration::Campaign do |campaign|
      user.can_edit?(campaign.campaignable)
    end

    can [:new, :create, :edit, :update, :destroy, :move_up, :move_down],
        Registration::Policy do |policy|
      user.can_edit?(policy.registration_campaign.campaignable)
    end
  end
end
