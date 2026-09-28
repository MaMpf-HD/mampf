# Opens the support's search for people and the correction of their locked
# personal data to the support and to admins.
class SupportAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :edit, :update], :support if user.support? || user.admin?
  end
end
