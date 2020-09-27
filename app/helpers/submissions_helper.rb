# Submissions Helper
module SubmissionsHelper
  def cancel_editing_submission_path(submission)
    return cancel_edit_submission_path(submission) if submission.persisted?
    cancel_new_submission_path(params: { assignment_id: submission.assignment.id })
  end

  def partner_selection(user, lecture)
    user.submission_partners(lecture).map { |u| [u.name, u.id] }
  end

  def admissible_invitee_selection(user, submission, lecture)
  	submission.admissible_invitees(user).map { |u| [u.name, u.id] }
  end

  def probable_invitee_ids(user, submission)
  	(submission.assignment.previous&.submission_partners(user).to_a -
  		(submission.users + submission.invited_users)).map(&:id)
  end

  def submission_color(submission, assignment)
  	return 'bg-mdb-color-lighten-7' unless assignment.current?
  	return 'bg-submission-green' if submission&.manuscript
  	return 'bg-submission-yellow' if submission
  	'bg-submission-red'
  end
end