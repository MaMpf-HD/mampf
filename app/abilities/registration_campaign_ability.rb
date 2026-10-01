class RegistrationCampaignAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :create, :show, :edit, :update, :destroy, :open, :close,
         :reopen, :revert_to_draft, :self_service, :finalize, :allocate,
         :view_allocation, :unassigned, :rejected, :confirm_end, :end_without_allocation],
        Registration::Campaign do |campaign|
      user.can_edit?(campaign.campaignable)
    end
  end
end
