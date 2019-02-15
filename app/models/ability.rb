# Ability class
# Class for defining access rights for admins, editors and normal users
# using the cancancan gem
class Ability
  # See the wiki for details:
  # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.

    # guest user (not logged in)
    user ||= User.new
    if user.admin?
      can :manage, :all
    elsif user.editor?
      # :read is a cancancan alias for index and show actions
      can [:read, :inspect], :all
      cannot :index, Announcement
      can :manage, [:administration, Item, Referral]
      # :create is a cancancan alias for new and create actions
      can :create, [Chapter, Lecture, Lesson, Medium, Section]
      # :update is a cancancan alias for update and edit actions

      can [:new, :create], Announcement

      # only users who are editors of a chapter's lecture can edit, update
      # or destroy them
      can [:update, :destroy], Chapter do |chapter|
        chapter.lecture.edited_by?(user)
      end

      # anyone should be able to get a sidebar and see the announcements
      can [:render_sidebar, :organizational, :show_announcements], Lecture

      # editors are only allowed to edit, not to destroy courses
      can :update, Course do |course|
        course.edited_by?(user)
      end

      can [:update, :update_teacher, :update_editors, :destroy, :add_forum,
           :lock_forum, :unlock_forum, :destroy_forum],
          Lecture do |lecture|
        lecture.edited_by?(user)
      end

      can [:update, :destroy], Lesson do |lesson|
        lesson.lecture.edited_by?(user)
      end
      can [:modal, :list_sections], Lesson

      can [:catalog, :search, :play, :display], Medium
      can [:update, :enrich, :add_item, :add_reference, :add_screenshot,
           :remove_screenshot, :export_toc, :export_references,
           :export_screenshot, :publish, :destroy], Medium do |m|
        m.edited_with_inheritance_by?(user)
      end

      can [:index, :destroy_all, :destroy_lecture_notifications,
           :destroy_news_notifications], Notification
      can :destroy, Notification do |n|
        n.recipient == user
      end

      can [:update, :destroy], Section do |section|
        section.lecture.edited_by?(user)
      end

      can [:list_tags, :list_sections], Section

      can :manage, Tag
      can :display_cyto, Tag

      cannot :read, Term

      cannot :read, User
      can :update, User do |u|
        user == u
      end
      can :teacher, User
    else
      can :read, :all
      cannot :read, [:administration, Term, User, Announcement]
      # guest users can play/display media only when their release status
      # is 'all', logged in users can do that unless the release status is
      # 'locked'
      can [:play, :display], Medium do |medium|
        if !user.new_record?
          medium.released_with_inheritance? && !medium.locked?
        else
          medium.released_with_inheritance? && medium.free?
        end
      end
      cannot [:index, :update, :create], Tag
      can :display_cyto, Tag
      can :teacher, User
      # anyone should be able to get a sidebar and see the announcements
      can [:render_sidebar, :show_announcements, :organizational], Lecture
      can [:index, :destroy_all], Notification
      can :destroy, Notification do |n|
        n.recipient == user
      end
      cannot :show, Medium do |medium|
        !medium.released_with_inheritance? || medium.locked?
      end
      cannot :show, Section do |section|
        !section.lecture.released?
      end
      cannot :show, Lesson do |lesson|
        !lesson.lecture.released?
      end
      can [:index, :destroy_all, :destroy_lecture_notifications,
           :destroy_news_notifications], Notification
    end
  end
end
