class VoucherAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:create, :invalidate], Voucher do |voucher|
      user.can_update_personell?(voucher.lecture)
    end
  end
end
