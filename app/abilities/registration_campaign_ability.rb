class RegistrationCampaignAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :create, :show, :edit, :update, :destroy, :open, :close,
         :reopen, :finalize, :force_finalize, :allocate,
         :view_allocation, :unassigned],
        Registration::Campaign do |campaign|
      user.can_edit?(campaign.campaignable)
    end
  end
end
