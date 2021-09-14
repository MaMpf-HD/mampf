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
      cannot [:show_announcements, :organizational], Lecture do |lecture|
        !lecture.in?(user.lectures)
      end
    elsif user.editor? || user.teacher?
      # :read is a cancancan alias for index and show actions
      can [:read], :all

      can :manage, :erdbeere

      can :manage, Referral do |referral|
        user.can_edit?(referral.medium)
      end

      can :manage, Item do |item|
        item.medium.nil? ||  user.can_edit?(item.medium?)
      end

      can :create, [Lecture, Lesson, Section]

      # only users who are editors of a talk's lecture or who are speakers
      # can edit, update, destroy or assemble them
      can [:update, :destroy, :assemble, :modify], Talk do |talk|
        talk.lecture.edited_by?(user) || talk.given_by?(user)
      end

      cannot :show, Talk do |talk|
        !talk.visible_for_user?(user)
      end

      # anyone should be able to get a sidebar and see the announcements
      can [:organizational, :show_announcements,
           :show_structures, :search_examples, :search, :show_random_quizzes,
           :display_course, :subscribe_page],
          Lecture

      can [:take_random_quiz, :render_question_counter, :search], Course

      # editors are only allowed to edit, not to destroy courses
      can :update, Course do |course|
        course.edited_by?(user)
      end

      can [:update, :update_teacher, :update_editors, :destroy, :add_forum,
           :publish, :lock_forum, :unlock_forum, :destroy_forum, :import_media,
           :remove_imported_medium, :show_subscribers,
           :edit_structures, :close_comments, :open_comments],
          Lecture do |lecture|
        lecture.edited_by?(user)
      end
      cannot [ :show_announcements, :organizational], Lecture do |lecture|
        !lecture.in?(user.lectures)
      end

      can [:update, :destroy], Lesson do |lesson|
        lesson.lecture.edited_by?(user)
      end
      can [:modal, :list_sections], Lesson

      can :start, :main

      can [:index, :destroy_all, :destroy_lecture_notifications,
           :destroy_news_notifications], Notification
      can :destroy, Notification do |n|
        n.recipient == user
      end

      can :reassign, Remark

      can [:update, :destroy], Section do |section|
        section.lecture.edited_by?(user)
      end

      can [:list_tags, :list_sections, :display], Section

      can [:index, :new, :create, :join,:cancel_edit, :cancel_new,
           :redeem_code, :enter_code], Submission

      # an editor might still be a student in some other course
      can [:edit, :update, :destroy, :leave,
           :refresh_token, :enter_invitees, :invite], Submission do |submission|
        user.in?(submission.users)
      end

      can [:add_correction, :delete_correction, :select_tutorial, :move,
           :cancel_action, :accept, :reject, :edit_correction,
           :cancel_edit_correction],
          Submission do |submission|
        user.in?(submission.tutorial.tutors)
      end

      can [:show_manuscript, :show_correction], Submission do |submission|
          user.in?(submission.users) || user.in?(submission.tutorial.tutors)
      end

      can :manage, Tag
      can [:display_cyto, :fill_tag_select, :fill_course_tags,
           :take_random_quiz, :postprocess], Tag

      cannot :read, Term

      can [:new, :create, :cancel_edit, :cancel_new, :overview, :index,
           :bulk_download_submissions, :bulk_download_corrections, :export_teams], Tutorial

      can [:index, :validate_certificate], Tutorial do |tutorial|
        user.tutor?
      end

      can [:edit, :update, :destroy], Tutorial do |tutorial|
        tutorial.lecture.edited_by?(user)
      end

      can [:bulk_download_submissions, :bulk_upload, :export_teams], Tutorial do |tutorial|
        user.in?(tutorial.tutors)
      end

      cannot :read, User
      can :update, User do |u|
        user == u
      end
      can [:teacher, :fill_user_select, :list, :delete_account], User
      can :manage, [:event, :vertex]
      can [:take, :proceed, :preview], Quiz
      # can [:new, :create, :edit, :open, :close, :set_alternatives,
      #      :get_votes_count], Clicker
      # can [:associate_question, :remove_question, :destroy], Clicker do |clicker|
      #   clicker.editor == user
      # end
      can [:linearize, :set_root, :set_level,
           :update_default_target, :delete_edge], Quiz do |quiz|
        quiz.edited_with_inheritance_by?(user)
      end

      can :claim, QuizCertificate

      can :validate, QuizCertificate do |quiz_certificate|
        user.tutor?
      end
    else
      can :read, :all
      can :start, :main
      cannot :read, [Term, User]
      cannot :index, Interaction

      can [:edit, :open, :close, :set_alternatives, :get_votes_count], Clicker

      can [:take, :proceed], Quiz

      #cannot :show, Lecture  do |lecture|
      #  !lecture.in?(user.lectures)
      #end

      can [:render_question_counter, :take_random_quiz], Course do |course|
        course.subscribed_by?(user)
      end

      cannot [:update, :create], Tag
      can [:display_cyto, :fill_course_tags, :take_random_quiz], Tag
      can :teacher, User

      can [:show_announcements, :organizational,
           :show_structures, :search_examples, :search, :show_random_quizzes,
           :display_course, :subscribe_page], Lecture
      cannot [:show_announcements, :organizational], Lecture do |lecture|
        !lecture.in?(user.lectures)
      end
      can [:index, :destroy_all], Notification
      can :destroy, Notification do |n|
        n.recipient == user
      end

      cannot :show, Section do |section|
        !section.visible_for_user?(user)
      end
      cannot :show, Lesson do |lesson|
        !lesson.visible_for_user?(user)
      end
      cannot :index, Interaction
      can [:index, :destroy_all, :destroy_lecture_notifications,
           :destroy_news_notifications], Notification

      can [:show_example, :find_example, :show_property, :show_structure,
           :find_tags, :display_info], :erdbeere

      can [:index, :new, :create, :join,:cancel_edit, :cancel_new,
           :redeem_code, :enter_code], Submission

      can [:edit, :update, :destroy, :leave,
           :refresh_token, :enter_invitees,
           :invite], Submission do |submission|
        user.in?(submission.users)
      end

      can [:show_correction, :show_manuscript], Submission do |submission|
        user.in?(submission.users) || user.in?(submission.tutorial.tutors)
      end

      can [:add_correction, :delete_correction, :select_tutorial, :move,
           :cancel_action, :accept, :reject, :edit_correction,
           :cancel_edit_correction],
          Submission do |submission|
        user.in?(submission.tutorial.tutors)
      end

      can :fill_tag_select, Tag

      # only generic users who are speakers can assemble the talk
      can [:assemble, :modify], Talk do |talk|
        talk.given_by?(user) && talk.visible_for_user?(user)
      end

      cannot :show, Talk do |talk|
        !talk.visible_for_user?(user)
      end

      can [:index, :validate_certificate], Tutorial do |tutorial|
        user.tutor?
      end

      can [:bulk_download_submissions, :bulk_upload, :export_teams], Tutorial do |tutorial|
        user.in?(tutorial.tutors)
      end

      can :claim, QuizCertificate

      can :validate, QuizCertificate do |quiz_certificate|
        user.tutor?
      end

      can :delete_account, User

      can :manage, Referral do |referral|
        user.can_edit?(referral.medium)
      end

      can :manage, Item do |item|
        item.medium.nil? ||  user.can_edit?(item.medium)
      end

      can [:linearize, :set_root, :set_level,
           :update_default_target, :delete_edge], Quiz do |quiz|
        quiz.edited_with_inheritance_by?(user)
      end

      can :manage, [:event]

      can :manage, :vertex do |quiz|
        user.can_edit?(@quiz)
      end

      can [:create, :update, :destroy], Answer do |answer|
        answer.question.edited_with_inheritance_by?(user)
      end
    end
  end
end