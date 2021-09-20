class LectureAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :new, Lecture do
      user.course_editor?
    end

    can :create, Lecture do |lecture|
      user.can_edit?(lecture.course)
    end

    can [:edit, :update, :update_teacher, :update_editors, :destroy, :add_forum,
         :publish, :lock_forum, :unlock_forum, :destroy_forum, :import_media,
         :remove_imported_medium, :show_subscribers,
         :edit_structures, :close_comments, :open_comments],
        Lecture do |lecture|
      user.can_edit?(lecture)
    end

    # there is a redirect to the subscription page inside the controller
    # if the lecture is not a subscribed lecture of the user
    can :show, Lecture

    can :search, Lecture

    can [:show_announcements, :organizational, :show_structures,
         :search_examples, :show_random_quizzes,
         :display_course], Lecture do |lecture|
      lecture.in?(user.lectures)
    end

    can :subscribe_page, Lecture do |lecture|
      lecture.published? || !user.generic?
    end
  end
end