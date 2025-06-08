class SubmissionInvite
  def initialize(user)
    @user = user
  end

  # For the given assignment, finds the submission that the current user is
  # invited to, if any. Returns a hash with the submission token and the user who
  # created it, or nil if no submission is found.
  #
  # There should never be multiple submissions for the same user and assignment,
  # but if there are, we log this as an error and return the first one found.
  def invites_for(assignment)
    return nil unless @user && assignment

    submissions = Submission.where(assignment: assignment)
                            .where("? = ANY(invited_user_ids)", @user.id)
    return nil if submissions.empty?

    if submissions.count > 1
      Rails.error.unexpected(
        "Multiple submissions found for user #{@user.id} and assignment #{assignment.id}"
      )
    end
    submission = submissions.first

    inviter = UserSubmissionJoin.find_by(submission_id: submission.id)&.user
    if inviter.nil?
      Rails.error.unexpected(
        "No inviter found for submission #{submission.id} of assignment #{assignment.id}"
      )
      inviter_name = "Unknown Inviter"
    else
      inviter_name = inviter.name
    end

    { token: submission.token, inviter: inviter_name }
  end
end
