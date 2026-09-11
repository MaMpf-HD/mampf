# Submissions Helper
module SubmissionsHelper
  include Rosters::RosterCaching

  def cancel_editing_submission_path(submission)
    return cancel_edit_submission_path(submission) if submission.persisted?

    cancel_new_submission_path(params: { assignment_id: submission.assignment.id })
  end

  def partner_preselection(user, lecture)
    user.recent_submission_partners(lecture).map(&:id)
  end

  def probable_invitee_ids(user, submission, lecture)
    partner_preselection(user, lecture) -
      (submission.users + submission.invited_users).map(&:id)
  end

  # Whether the reader has handed anything in to this lecture - the one fact
  # that tells a lecture from before the groups apart. Cached like the seat:
  # every open card asks, and the answer is one per lecture.
  def handed_in_before?(lecture)
    roster_cache[:handed_in].fetch(lecture.id) do
      roster_cache[:handed_in][lecture.id] =
        UserSubmissionJoin.joins(submission: :assignment)
                          .exists?(assignments: { lecture_id: lecture.id },
                                   user: current_user)
    end
  end

  def rostered_tutorial_for(lecture)
    roster_cache[:tutorial].fetch(lecture.id) do
      roster_cache[:tutorial][lecture.id] = current_user.rostered_tutorial_in(lecture)
    end
  end

  def submission_late_color(submission)
    return "" unless submission.too_late?
    return "" unless submission.accepted.nil?

    "bg-submission-orange"
  end

  def late_submission_info(submission, tutorial)
    text = t("submission.late")
    return text unless submission.accepted.nil? && current_user.in?(tutorial.tutors)

    "#{text} (#{t("tutorial.late_submission_decision")})"
  end

  def correction_display_mode(submission)
    accepted = submission.assignment.accepted_file_type
    non_inline = Assignment.non_inline_file_types
    return t("buttons.show") unless accepted.in?(non_inline)

    t("buttons.download")
  end
end
