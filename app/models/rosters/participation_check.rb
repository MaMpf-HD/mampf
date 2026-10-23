module Rosters
  # The lectures of the running term in which the user is enrolled but in no
  # group and has not said yet that they still take part. A student who left
  # their tutorial often believes they left the lecture, which stays on their
  # dashboard; the participation check asks them.
  class ParticipationCheck
    def initialize(user)
      @user = user
    end

    # One query for most users, since it runs on every request of a
    # signed-in user.
    def due?
      return @due if defined?(@due)

      @due = candidates.exists? && lectures.any?
    end

    # The editors and admins that #candidates lets through drop out here.
    def lectures
      @lectures ||= candidates.includes(:course, :term)
                              .select { |lecture| Registration::Participation.allowed?(@user, lecture) }
                              .sort_by(&:title)
    end

    private

      # Leaves out in SQL whom the check never asks: a tutor or the teacher of
      # the lecture, and someone whose registration for a group still runs,
      # who waits for a group rather than being without one.
      def candidates
        unanswered = @user.lecture_memberships.where(participation_confirmed_at: nil)
        base = Lecture.published.where(term: Term.where(active: true),
                                       id: unanswered.select(:lecture_id))
                      .where.not(teacher_id: @user.id)
        with_groups = base.where(id: Tutorial.select(:lecture_id))
                          .or(base.where(id: Talk.select(:lecture_id)))
                          .or(base.where(id: lecture_cohorts.select(:context_id)))
        with_groups.where.not(id: own_tutorials.select(:lecture_id))
                   .where.not(id: own_talks.select(:lecture_id))
                   .where.not(id: lecture_cohorts.where(id: own_cohort_ids).select(:context_id))
                   .where.not(id: tutored_lecture_ids)
                   .where.not(id: TutorAppointment.where(user: @user).select(:lecture_id))
                   .where.not(id: awaited_lecture_ids)
      end

      def awaited_lecture_ids
        registered = Registration::UserRegistration.where(user: @user)
                                                   .where.not(status: :rejected)
        Registration::Campaign.non_exam
                              .where(campaignable_type: "Lecture",
                                     status: UserPlaces::RUNNING_CAMPAIGN_STATUSES,
                                     id: registered.select(:registration_campaign_id))
                              .select(:campaignable_id)
      end

      def tutored_lecture_ids
        Tutorial.where(id: TutorTutorialJoin.where(tutor: @user).select(:tutorial_id))
                .select(:lecture_id)
      end

      def lecture_cohorts
        Cohort.where(context_type: "Lecture")
      end

      def own_tutorials
        Tutorial.where(id: TutorialMembership.where(user: @user).select(:tutorial_id))
      end

      def own_talks
        Talk.where(id: SpeakerTalkJoin.where(speaker: @user).select(:talk_id))
      end

      def own_cohort_ids
        CohortMembership.where(user: @user).select(:cohort_id)
      end
  end
end
