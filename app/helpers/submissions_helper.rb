# Submissions Helper
module SubmissionsHelper
  def cancel_editing_submission_path(submission)
    return cancel_edit_submission_path(submission) if submission.persisted?
    cancel_new_submission_path(params: { assignment_id: submission.assignment.id })
  end

  def partner_selection(user, lecture)
    user.submission_partners(lecture).map { |u| [u.tutorial_name, u.id] }
  end

  def partner_preselection(user, lecture)
    user.recent_submission_partners(lecture).map(&:id)
  end

  def admissible_invitee_selection(user, submission, lecture)
  	submission.admissible_invitees(user).map { |u| [u.tutorial_name, u.id] }
  end

  def probable_invitee_ids(user, submission, lecture)
  	partner_preselection(user, lecture) -
  		(submission.users + submission.invited_users).map(&:id)
  end

  def invitations_possible?(submission, user)
  	return false if submission.admissible_invitees(user).empty?
  	return true unless submission.assignment.lecture.submission_max_team_size
		submission.users.size <
			submission.assignment.lecture.submission_max_team_size
  end

  def submission_color(submission, assignment)
  	if assignment.active?
  		return 'bg-submission-green' if submission&.manuscript
  		return 'bg-submission-yellow' if submission
  		return 'bg-submission-red'
  	else
  		return 'bg-submission-darker-green' if submission&.correction
      if submission&.manuscript && submission.too_late?
        return 'bg-submission-orange' if submission.accepted.nil?
        return 'bg-submission-green' if submission.accepted
        return 'bg-submission-red'
      end
  		return 'bg-submission-green' if submission&.manuscript
  		return 'bg-submission-red'
  	end
  end

  def submission_status_icon(submission, assignment)
    if assignment.active?
      return 'far fa-smile' if submission&.manuscript
      return 'fas fa-exclamation-triangle'
    else
      return 'far fa-smile' if submission&.correction
      if submission&.manuscript && submission.too_late?
        return 'fas fa-hourglass-start' if submission.accepted
        return 'fas fa-exclamation-triangle'
      end
      return 'fas fa-hourglass-start' if submission&.manuscript
      return 'fas fa-exclamation-triangle'
    end
  end

  def submission_status_text(submission, assignment)
    if assignment.active?
      return t('submission.okay') if submission&.manuscript
      return t('submission.no_file') if submission
      return t('submission.nothing')
    else
      return t('submission.with_correction') if submission&.correction
      if submission&.manuscript && submission.too_late?
        return t('submission.too_late') if submission.accepted.nil?
        return t('submission.too_late_accepted') if submission.accepted
        return t('submission.too_late_rejected')
      end
      return t('submission.under_review') if submission&.manuscript
      return t('submission.no_file') if submission
      return t('submission.nothing')
    end
  end

  def submission_status(submission, assignment)
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
    return '' unless submission.accepted.nil?
    'bg-submission-orange'
  end

  def late_submission_info(submission)
    text = t('submission.late')
    return text unless submission.accepted.nil?
    "#{text} (#{t('tutorial.late_submission_decision')})"
  end

  def correction_display_mode(submission)
  	accepted = submission.assignment.accepted_file_type
  	non_inline = Assignment.non_inline_file_types
  	return t('buttons.show') unless accepted.in?(non_inline)
  	t('buttons.download')
  end
end