class RegistrationPolicyAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create, :edit, :update, :destroy, :move_up, :move_down],
        Registration::Policy do |policy|
      user.can_edit?(policy.registration_campaign.campaignable)
    end
  end
end
