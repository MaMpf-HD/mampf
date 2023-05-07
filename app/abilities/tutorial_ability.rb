class TutorialAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create, :edit, :update, :destroy, :cancel_edit,
         :cancel_new], Tutorial do |tutorial|
      user.can_update_personell?(tutorial.lecture)
    end

    can :overview, Tutorial do |tutorial, lecture|
      user.editor_or_teacher_in?(lecture)
    end

    can :index, Tutorial do |tutorial, lecture|
      user.in?(lecture.tutors) || user.editor_or_teacher_in?(lecture)
    end

    can [:bulk_download_submissions, :bulk_download_corrections, :bulk_upload,
         :export_teams], Tutorial do |tutorial|
      user.in?(tutorial.tutors) ||
      user.editor_or_teacher_in?(tutorial.lecture)
    end

    can :validate_certificate, Tutorial do
      user.tutor? || user.can_edit_teachables?
    end
  end
end




