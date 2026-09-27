# Opens the read-only records office pages, across all lectures, to the
# records office and to admins.
class RecordsOfficeAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :grades, :admissions, :emails], :records_office do
      user.records_office? || user.admin?
    end
  end
end
