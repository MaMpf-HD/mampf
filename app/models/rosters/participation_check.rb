module Rosters
  # The lectures of the running term in which the user is enrolled but in no
  # group and has not said yet that they still take part. Without a group
  # nobody can hand in a sheet, and a student who left their tutorial often
  # believes they left the lecture; the participation check asks them.
  class ParticipationCheck
    def initialize(user)
      @user = user
    end

    # One query, since it runs on every request of a signed-in user.
    def due?
      return @due if defined?(@due)

      @due = candidates.exists? && lectures.any?
    end

    def lectures
      @lectures ||= candidates.includes(:course, :term)
                              .select { |lecture| asked_in?(lecture) }
                              .sort_by(&:title)
    end

    private

      def candidates
        term = Term.active
        return Lecture.none unless term

        unanswered = @user.lecture_memberships.where(participation_confirmed_at: nil)
        base = Lecture.where(term: term, id: unanswered.select(:lecture_id))
        with_groups = base.where(id: Tutorial.select(:lecture_id))
                          .or(base.where(id: Talk.select(:lecture_id)))
                          .or(base.where(id: lecture_cohorts.select(:context_id)))
        with_groups.where.not(id: own_tutorials.select(:lecture_id))
                   .where.not(id: own_talks.select(:lecture_id))
                   .where.not(id: lecture_cohorts.where(id: own_cohort_ids).select(:context_id))
      end

      # Staff and tutors are no students here; someone whose registration
      # still runs waits for a group rather than being without one.
      def asked_in?(lecture)
        Registration::Participation.allowed?(@user, lecture) && !waiting_for_group?(lecture)
      end

      def waiting_for_group?(lecture)
        Registration::UserRegistration
          .where(user: @user)
          .where.not(status: :rejected)
          .joins(:registration_campaign)
          .merge(Registration::Campaign.non_exam
                                       .where(campaignable: lecture,
                                              status: UserPlaces::RUNNING_CAMPAIGN_STATUSES))
          .exists?
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
