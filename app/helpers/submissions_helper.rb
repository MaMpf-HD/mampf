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

  def invitations_possible?(submission, user)
  	return false if submission.admissible_invitees(user).empty?
  	return true unless submission.assignment.lecture.submission_max_team_size
		submission.users.size <
			submission.assignment.lecture.submission_max_team_size
  end

  def submission_color(submission, assignment)
  	if assignment.current?
  		return 'bg-submission-green' if submission&.manuscript
  		return 'bg-submission-yellow' if submission
  		return 'bg-submission-red'
  	elsif assignment.previous?
  		return 'bg-submission-darker-green' if submission&.correction
      return 'bg-submission-orange' if submission&.manuscript && submission.too_late?
  		return 'bg-submission-green' if submission&.manuscript
  		return 'bg-submission-red'
  	end
	  'bg-mdb-color-lighten-7'
  end

  def submission_status_icon(submission, assignment)
    return unless assignment.current? || assignment.previous?
    if assignment.current?
      return 'far fa-smile' if submission&.manuscript
      return 'fas fa-exclamation-triangle'
    elsif assignment.previous?
      return 'far fa-smile' if submission&.correction
      return 'fas fa-exclamation-triangle' if submission&.manuscript && submission.too_late?
      return 'fas fa-hourglass-start' if submission&.manuscript
      return 'fas fa-exclamation-triangle'
    end
  end

  def submission_status_text(submission, assignment)
    return unless assignment.current? || assignment.previous?
    if assignment.current?
      return t('submission.okay') if submission&.manuscript
      return t('submission.no_file') if submission
      return t('submission.nothing')
    elsif assignment.previous?
      return t('submission.with_correction') if submission&.correction
      return t('submission.too_late') if submission&.manuscript && submission.too_late?
      return t('submission.under_review') if submission&.manuscript
      return t('submission.no_file') if submission
      return t('submission.nothing')
    end
  end

  def submission_status(submission, assignment)
    return unless assignment.current? || assignment.previous?
    tag.i class: [submission_status_icon(submission, assignment), 'fa-lg'],
          data: { toggle: 'tooltip'},
          title: submission_status_text(submission, assignment)
  end

  def show_submission_footer?(submission, assignment)
    return true if assignment.active?
    return false if assignment.totally_expired?
    return false if submission&.correction
    true
  end

  def submission_late_color(submission)
    return '' unless submission.too_late?
    'bg-submission-orange'
  end
end