class SectionAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:show, :toggle_completion], Section do |section|
      section.visible_for_user?(user)
    end

    can [:new, :edit, :create, :update, :destroy,
         :display], Section do |section|
      user.can_edit?(section.lecture)
    end
  end
end
