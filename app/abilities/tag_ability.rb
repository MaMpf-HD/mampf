class TagAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:show, :display_cyto, :fill_course_tags, :take_random_quiz,
         :fill_tag_select], Tag

    can [:new, :edit, :update, :create, :destroy, :modal, :identify,
         :search, :postprocess, :render_tag_title], Tag do
      !user.generic?
    end
  end
end
