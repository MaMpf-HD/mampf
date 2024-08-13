class VoucherAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:create, :destroy], Voucher do |voucher|
      user.can_update_personell?(voucher.lecture)
    end

    can :redeem, Voucher
  end
end
