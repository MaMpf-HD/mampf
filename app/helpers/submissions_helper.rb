# Submissions Helper
module SubmissionsHelper
  def cancel_editing_submission_path(submission)
    return cancel_edit_submission_path(submission) if submission.persisted?
    cancel_new_submission_path(params: { assignment_id: submission.assignment.id })
  end
end