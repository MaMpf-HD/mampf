class CohortAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create, :edit, :update, :destroy], Cohort do |cohort|
      context = cohort.context
      next false unless context

      if context.is_a?(Lecture)
        user.can_edit?(context)
      else
        false
      end
    end
  end
end
