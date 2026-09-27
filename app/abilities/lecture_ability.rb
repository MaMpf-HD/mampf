class LectureAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :new, Lecture do
      user.course_editor? || user.admin?
    end

    can :create, Lecture do |lecture|
      user.can_edit?(lecture.course)
    end

    can [:edit, :update, :update_teacher, :update_editors, :destroy, :add_forum,
         :publish, :lock_forum, :unlock_forum, :destroy_forum, :import_media,
         :remove_imported_medium, :show_subscribers, :import_toc,
         :close_comments, :open_comments],
        Lecture do |lecture|
      user.can_edit?(lecture)
    end

    # there is a redirect to the lecture's home page inside the controller
    # if the lecture's content is not accessible to the user (see
    # Lecture#content_accessible_by?)
    can :show, Lecture

    can :search, Lecture

    can [:show_announcements, :organizational, :show_random_quizzes,
         :display_course], Lecture do |lecture|
      lecture.content_accessible_by?(user)
    end

    can [:self_materialize, :enroll], Lecture do |lecture|
      Registration::Participation.allowed?(user, lecture)
    end
  end
end
