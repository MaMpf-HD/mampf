# Decides who takes part in a lecture: who bookmarked it, who is on one of its
# rosters, and who has a registration for it still running. Its announcements,
# new media and comment notices go to them, and only they see media released
# to participants. Reading an open lecture needs none of these, so a reader
# who wants its news bookmarks it.
module LectureAudience
  RUNNING_CAMPAIGN_STATUSES = [:open, :closed, :processing].freeze

  module_function

  def users(lecture_ids)
    user_id_scopes(lecture_ids).map { |ids| User.where(id: ids) }.reduce(:or)
  end

  def user_id_scopes(lecture_ids)
    [LectureBookmark.where(lecture_id: lecture_ids).select(:user_id),
     LectureMembership.where(lecture_id: lecture_ids).select(:user_id),
     CohortMembership.joins(:cohort)
                     .where(cohorts: { context_type: "Lecture", context_id: lecture_ids })
                     .select(:user_id),
     SpeakerTalkJoin.joins(:talk).where(talks: { lecture_id: lecture_ids })
                    .select(:speaker_id),
     ExamRosterEntry.active.joins(:exam).where(exams: { lecture_id: lecture_ids })
                    .select(:user_id),
     running_registrations(lecture_ids).select(:user_id)]
  end

  def lectures_of(user)
    lecture_id_scopes(user).map { |ids| Lecture.where(id: ids) }.reduce(:or)
  end

  def lecture_id_scopes(user)
    running = Registration::Campaign.where(
      id: Registration::UserRegistration.where(user: user).where.not(status: :rejected)
                                        .select(:registration_campaign_id),
      status: RUNNING_CAMPAIGN_STATUSES, campaignable_type: "Lecture"
    )
    [LectureBookmark.where(user: user).select(:lecture_id),
     LectureMembership.where(user: user).select(:lecture_id),
     Cohort.where(context_type: "Lecture",
                  id: CohortMembership.where(user: user).select(:cohort_id))
           .select(:context_id),
     Talk.where(id: SpeakerTalkJoin.where(speaker: user).select(:talk_id)).select(:lecture_id),
     Exam.where(id: ExamRosterEntry.active.where(user: user).select(:exam_id))
         .select(:lecture_id),
     running.select(:campaignable_id)]
  end

  def running_registrations(lecture_ids)
    Registration::UserRegistration
      .where.not(status: :rejected)
      .joins(:registration_campaign)
      .merge(Registration::Campaign.where(status: RUNNING_CAMPAIGN_STATUSES,
                                          campaignable_type: "Lecture",
                                          campaignable_id: lecture_ids))
  end
end
