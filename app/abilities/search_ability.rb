class SearchAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :index, :search

    # Media and tags are searched to be edited, which is the teaching staff's.
    can :staff, :search do
      !user.generic?
    end
  end
end
