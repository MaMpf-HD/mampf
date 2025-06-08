class SubmissionInvite
  def initialize(user)
    @user = user
  end

  # For the given assignment, finds the submission that the current user is
  # invited to, if any. Returns a hash with the submission token and the user who
  # created it, or nil if no submission is found.
  #
  # Raises an error if multiple submissions are found for the user and assignment.
  def invites_for(assignment)
    return false unless @user && assignment

    submissions = Submission.where(assignment: assignment)
                            .where("? = ANY(invited_user_ids)", @user.id)
    return nil if submissions.empty?

    if submissions.count > 1
      raise("Multiple submissions found for user #{@user.id} and assignment #{assignment.id}")
    end

    submission = submissions.first
    inviter = UserSubmissionJoin.find_by(submission_id: submission.id)&.user
    { token: submission.token, inviter: inviter.name }
  end
end
