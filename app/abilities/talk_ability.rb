class TalkAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :show, Talk do |talk|
      talk.visible_for_user?(user)
    end

    can [:new, :edit, :create, :update, :destroy], Talk do |talk|
      talk.lecture && talk.lecture.edited_by?(user)
    end

    can [:assemble, :modify], Talk do |talk|
      talk.given_by?(user) && talk.visible_for_user?(user)
    end
  end
end
