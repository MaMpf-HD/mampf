# Grants the support its account pages: finding people, correcting their
# personal data and sending the mails that get them back in. Kept apart from
# the rights of teaching and editing content.
class SupportAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    return unless user.support? || user.admin?

    can :index, :support

    can [:edit, :update, :unlock, :password_reset, :confirmation], User do |person|
      user.admin? || !person.admin?
    end

    return unless user.admin?

    can :assign_roles, User

    # Only another admin may change an account's admin rights.
    can :assign_admin, User do |person|
      person != user
    end

    # Accounts of admins, teachers and editors hold lectures, courses and
    # media; they stay.
    can :destroy, User do |person|
      person.generic? && person != user
    end
  end
end
