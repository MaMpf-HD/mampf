class RemarkAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:edit, :update, :reassign, :cancel_remark_basics], Remark do |remark|
      user.can_edit?(remark)
    end
  end
end
