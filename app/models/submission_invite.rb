class SubmissionInvite
  def initialize(user)
    @user = user
  end

  # For the given assignment, finds all submissions that the current user is
  # invited to. Returns an array of hashes with the submission token and the user who
  # created it, or an empty array if no submissions are found.
  def invites_for(assignment)
    return [] unless @user && assignment

    submissions = Submission.where(assignment: assignment)
                            .where("? = ANY(invited_user_ids)", @user.id)
    return [] if submissions.empty?

    submissions.map do |submission|
      inviter = UserSubmissionJoin.find_by(submission_id: submission.id)&.user
      if inviter.nil?
        Rails.error.unexpected(
          "No inviter found for submission #{submission.id} of assignment #{assignment.id}"
        )
        inviter_name = "Unknown Inviter"
      else
        inviter_name = inviter.tutorial_name
      end
      { token: submission.token, inviter: inviter_name }
    end
  end
end
