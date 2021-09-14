class ChapterAbility
  include CanCan::Ability

  def initialize(user)
    can [:edit, :update, :create, :new, :destroy,
         :list_sections], Chapter do |chapter|
      chapter.lecture.present? && user.can_edit?(chapter.lecture)
    end
  end
end