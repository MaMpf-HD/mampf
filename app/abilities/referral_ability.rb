class ReferralAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:update, :edit, :create, :destroy], Referral do |referral|
      user.can_edit?(referral.medium)
    end

    can :list_items, Referral do
      !user.generic? || user.media_editor?
    end
  end
end