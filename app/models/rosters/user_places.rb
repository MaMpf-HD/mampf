module Rosters
  # Collects where a student takes part: the rosters they are on, the
  # registrations still running and the results recorded for them. Rosters,
  # exam lists and marking tables show the student's name and matriculation
  # number, so a student with a place may not decline to give them, but may
  # give up the places instead; a student with results may not.
  class UserPlaces
    RUNNING_CAMPAIGN_STATUSES = [:open, :closed, :processing].freeze

    # Raised when giving up the places of the named lectures leaves a place
    # the student was not shown.
    class PlacesChangedError < StandardError; end

    def initialize(user)
      @user = user
    end

    # One query, since it runs on every request of a user who declined.
    def any?
      exists?(roster_entry_scopes + [running_registrations] + result_scopes)
    end

    # Names the lectures rather than every group, so that the student
    # recognizes them in one line.
    def lectures
      (rosterables.map(&:lecture) + running_campaigns.map(&:campaignable))
        .grep(Lecture).uniq.sort_by(&:title)
    end

    # Points, a grade or a decided exam admission would stay behind without a
    # name, or be lost with the lecture roster, so they rule out giving up.
    def results?
      exists?(result_scopes)
    end

    # Withdraws the running registrations and leaves the rosters of the given
    # lectures, the lectures last because leaving one takes its groups along.
    # The campaigns are locked first, as allocation and finalization lock
    # them. Raises PlacesChangedError when a place outside these lectures
    # remains, and MaintenanceService::GradingDataPresentError when a talk or
    # an exam holds a result; either way nothing is given up.
    def give_up!(lectures)
      ActiveRecord::Base.transaction do
        withdraw_registrations!(lectures)
        leave_rosters!(lectures)
        raise(PlacesChangedError) if any?
      end
    end

    private

      def exists?(scopes)
        union = scopes.map { |scope| scope.select("1").to_sql }.join(" UNION ALL ")
        ActiveRecord::Base.connection.select_value("SELECT EXISTS (#{union})")
      end

      def result_scopes
        [Assessment::Participation.with_grading_data.where(user: @user),
         StudentPerformance::Certification.decided.where(user: @user)]
      end

      def withdraw_registrations!(lectures)
        running_campaigns.where(campaignable: lectures).order(:id).each do |campaign|
          campaign.lock!
          running_registrations.where(registration_campaign: campaign).find_each(&:destroy!)
        end
      end

      def leave_rosters!(lectures)
        service = MaintenanceService.new
        named = rosterables.select { |rosterable| rosterable.lecture.in?(lectures) }
        groups, lecture_rosters = named.partition { |rosterable| !rosterable.is_a?(Lecture) }
        (groups + lecture_rosters).each do |rosterable|
          service.remove_user!(@user, rosterable, notify: false)
        end
      end

      def roster_entry_scopes
        [TutorialMembership.where(user: @user),
         SpeakerTalkJoin.where(speaker: @user),
         lecture_cohort_memberships,
         ExamRosterEntry.active.where(user: @user),
         LectureMembership.where(user: @user)]
      end

      def rosterables
        Tutorial.where(id: TutorialMembership.where(user: @user).select(:tutorial_id)).to_a +
          Talk.where(id: SpeakerTalkJoin.where(speaker: @user).select(:talk_id)).to_a +
          Cohort.where(id: lecture_cohort_memberships.select(:cohort_id)).to_a +
          Exam.where(id: ExamRosterEntry.active.where(user: @user).select(:exam_id)).to_a +
          Lecture.where(id: LectureMembership.where(user: @user).select(:lecture_id)).to_a
      end

      # A cohort outside a lecture names no lecture to give up, so it is not a
      # place here; the app creates cohorts for lectures only.
      def lecture_cohort_memberships
        CohortMembership.where(user: @user)
                        .where(cohort: Cohort.where(context_type: "Lecture"))
      end

      def running_registrations
        Registration::UserRegistration
          .where(user: @user)
          .where.not(status: :rejected)
          .joins(:registration_campaign)
          .merge(Registration::Campaign.where(status: RUNNING_CAMPAIGN_STATUSES))
      end

      def running_campaigns
        Registration::Campaign.where(id: running_registrations.select(:registration_campaign_id))
      end
  end
end
