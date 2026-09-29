class CohortAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create, :edit, :update, :destroy], Cohort do |cohort|
      context = cohort.context
      next false unless context.is_a?(Lecture)

      user.can_edit?(context)
    end

    # A cohort has nothing to mark; who is in it is all its tutors see.
    can :participants, Cohort do |cohort|
      cohort.tutors.include?(user) ||
        (cohort.context.is_a?(Lecture) && user.can_edit?(cohort.context))
    end
  end
end
