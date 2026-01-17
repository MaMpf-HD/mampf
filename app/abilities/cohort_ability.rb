class CohortAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create, :edit, :update, :destroy], Cohort do |cohort|
      context = cohort.context
      next false unless context

      user.can_edit?(context)
    end
  end
end
