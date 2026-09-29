# Opens the read-only dean's office pages, across all lectures, to the
# dean's office and to admins.
class DeansOfficeAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :index, :deans_office do
      user.deans_office? || user.admin?
    end
  end
end
