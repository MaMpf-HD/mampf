module Rosters
  # get roster results for student
  class StudentMaterializedResultResolver
    def initialize(user)
      @user = user
    end

    def all_rosterized_for_lecture(lecture)
      rosterables =
        lecture.tutorials
               .includes(:tutors, :members)
               .where(id: TutorialMembership.where(user_id: @user.id).select(:tutorial_id))
               .to_a +
        lecture.cohorts
               .includes(:members)
               .where(id: CohortMembership.where(user_id: @user.id).select(:cohort_id))
               .to_a +
        lecture.talks
               .includes(:speakers, :members)
               .where(id: SpeakerTalkJoin.where(speaker_id: @user.id).select(:talk_id))
               .to_a

      rosterables.presence
    end
  end
end
