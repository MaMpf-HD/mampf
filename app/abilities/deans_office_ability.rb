# Grants the dean's office, and admins, the term overview across all
# lectures, without any right to change them.
class DeansOfficeAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :index, :deans_office do
      user.deans_office? || user.admin?
    end
  end
end
