class SubmissionAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :join, :cancel_edit, :cancel_new, :redeem_code,
         :enter_code, :seen, :seen_all], Submission

    # Enrolment is what this asks; the group is asked for by
    # `SubmissionsController#rostered_tutorial!`, which every way in goes
    # through and which says what is missing rather than "not authorized".
    can :create, Submission do |submission|
      lecture = submission.assignment&.lecture
      lecture.present? && user.proper_student_in?(lecture)
    end

    can [:edit, :update, :destroy, :leave, :refresh_token, :enter_invitees,
         :invite], Submission do |submission|
      user.in?(submission.users) && !submission.not_updatable?
    end

    # The file arrives before the hand-in is saved, so the upload asks for the
    # seat that `rostered_tutorial!` asks for later: without one, the file
    # could never become a hand-in and is not taken at all.
    can :upload_manuscript, Submission do |submission|
      lecture = submission.assignment&.lecture
      seated = lecture.present? && user.rostered_tutorial_in(lecture).present?
      if submission.persisted?
        seated && user.in?(submission.users) && !submission.not_updatable?
      else
        seated && user.proper_student_in?(lecture)
      end
    end

    can [:add_correction, :delete_correction, :edit_correction,
         :cancel_edit_correction], Submission do |submission|
      submission.tutorial.correctable_by?(user)
    end

    # Whether a late hand-in counts is the group's tutor's call.
    can [:accept, :reject], Submission do |submission|
      user.in?(submission.tutorial.tutors)
    end

    can [:show_manuscript, :show_correction], Submission do |submission|
      user.in?(submission.users) || submission.tutorial.correctable_by?(user)
    end
  end
end
