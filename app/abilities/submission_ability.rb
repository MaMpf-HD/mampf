class SubmissionAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :join, :cancel_edit, :cancel_new, :redeem_code,
         :enter_code], Submission

    can :create, Submission do |submission|
      lecture = submission.assignment&.lecture
      lecture.present? && user.proper_student_in?(lecture)
    end

    can [:edit, :update, :destroy, :leave, :refresh_token, :enter_invitees,
         :invite], Submission do |submission|
      user.in?(submission.users) && !submission.not_updatable?
    end

    can [:add_correction, :delete_correction,
         :cancel_action, :accept, :reject, :edit_correction,
         :cancel_edit_correction], Submission do |submission|
      user.in?(submission.tutorial.tutors)
    end

    can [:show_manuscript, :show_correction], Submission do |submission|
      user.in?(submission.users) || user.in?(submission.tutorial.tutors) ||
        user.in?(submission.tutorial.lecture.editors) ||
        user == submission.tutorial.lecture.teacher
    end
  end
end
