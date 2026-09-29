class SearchAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :index, :search

    # Staff look up media and tags to edit them; students have the general
    # search.
    can :staff, :search do
      !user.generic?
    end
  end
end
