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

  def rostered_tutorial_for(lecture)
    roster_cache[:tutorial].fetch(lecture.id) do
      roster_cache[:tutorial][lecture.id] = current_user.rostered_tutorial_in(lecture)
    end
  end

  # Tells the reader which tutorial they are in and where to write to its
  # tutors, the ones to ask when a hand-in or a correction is off.
  def tutorial_contact_line(lecture)
    tutorial = rostered_tutorial_for(lecture)
    return unless tutorial

    tutors = tutorial.tutors.to_a
    contacts = tutors.map do |tutor|
      safe_join([tutor.tutorial_name, " (", mail_to(tutor.email), ")"])
    end
    t("submission.hub.tutorial_line_html",
      count: tutors.size, tutorial: tutorial.title,
      tutor: tutors.first&.tutorial_name,
      email: tutors.first && mail_to(tutors.first.email),
      tutors: safe_join(contacts, ", "))
  end

  def submission_late_color(submission)
    return "" unless submission.too_late?
    return "" unless submission.accepted.nil?

    "bg-submission-orange"
  end
end
