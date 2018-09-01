# Ability class
class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:

    user ||= User.new # guest user (not logged in)
    if user.admin?
      can :manage, :all
      can :access, :rails_admin   # grant access to rails_admin
      can :dashboard              # grant access to the dashboard
    elsif user.editor?
      can :read, :all
      can :manage, :administration
      can :read, Course
      can :update, Course do |course|
        course.edited_by?(user)
      end
      can :read, Lecture
      can :update, Lecture do |lecture|
        lecture.edited_by?(user)
      end
      can :list_tags, Lecture
      can :new, Lecture
      can :destroy, Lecture do |lecture|
        lecture.edited_by?(user)
      end
      can :create, Lecture
      can :read, Chapter
      can :update, Chapter do |chapter|
        chapter.lecture.edited_by?(user)
      end
      can :destroy, Chapter do |chapter|
        chapter.lecture.edited_by?(user)
      end
      can :new, Chapter
      can :create, Chapter
      can :update, Section do |section|
        section.lecture.edited_by?(user)
      end
      can :destroy, Section do |section|
        section.lecture.edited_by?(user)
      end
      can :list_tags, Section do |section|
        section.lecture.edited_by?(user)
      end
      can :new, Section
      can :create, Section
      can :inspect, Chapter
      can :inspect, Lecture
      can :manage, Tag
      can :inspect, Course
      cannot :create, Course
      cannot :read, Term
      cannot :read, User
      can :update, User do |u|
        user == u
      end
      can :teacher, User
    else
      can :read, :all
      cannot :read, :administration
      cannot :index, Tag
      cannot :update, Tag
      cannot :create, Tag
      cannot :read, Term
      cannot :read, User
      can :teacher, User
    end

    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end
