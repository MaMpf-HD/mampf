module Rosters
  # Collects where a student takes part: the rosters they are on, the
  # registrations still running and the results recorded for them. Rosters,
  # exam lists and marking tables show the student's name and matriculation
  # number, so a student with a place may not decline to give them, but may
  # give up the places instead; a student with results may not.
  class UserPlaces
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
    # recognizes them in one line. A lecture with only a rejected registration
    # is among them, since giving it up withdraws that registration too.
    def lectures
      (rosterables.map(&:lecture) + withdrawable_campaigns.map(&:campaignable))
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
        leave!(lectures)
        raise(PlacesChangedError) if any?
      end
    end

    # Withdraws the running registrations and leaves the rosters of the given
    # lectures, without asking whether places elsewhere remain. Callers wrap
    # it in a transaction.
    def leave!(lectures)
      withdraw_registrations!(lectures)
      leave_rosters!(lectures)
    end

    # Withdraws the registrations in the given lectures, rejected ones too,
    # since a new allocation can turn them back into pending ones. Locks each
    # campaign first, as allocation and finalization do.
    def withdraw_registrations!(lectures)
      withdrawable_campaigns.where(campaignable: lectures).order(:id).each do |campaign|
        campaign.lock!
        next unless campaign.running?

        campaign.user_registrations.where(user: @user).find_each(&:destroy!)
      end
      dismiss_rejections!(lectures)
    end

    private

      def exists?(scopes)
        union = scopes.map { |scope| scope.select(Arel.sql("1")).arel }
                      .reduce { |left, right| Arel::Nodes::UnionAll.new(left, right) }
        query = Arel::SelectManager.new.project(Arel::Nodes::Exists.new(union))
        ActiveRecord::Base.connection.select_value(query)
      end

      def result_scopes
        [Assessment::Participation.with_grading_data.where(user: @user),
         StudentPerformance::Certification.decided.where(user: @user)]
      end

      # A rejection of a completed campaign would keep the lecture on the
      # dashboard (see User#lectures_with_registration_application); it is
      # dismissed rather than deleted, so the application stays on record.
      def dismiss_rejections!(lectures)
        completed = Registration::Campaign.where(campaignable: lectures, status: :completed)
                                          .non_exam
        Registration::UserRegistration.rejected.not_dismissed
                                      .where(user: @user, registration_campaign: completed)
                                      .find_each(&:dismiss!)
      end

      def leave_rosters!(lectures)
        service = MaintenanceService.new
        named = rosterables.select { |rosterable| rosterable.lecture.in?(lectures) }
        groups, lecture_rosters = named.partition { |rosterable| !rosterable.is_a?(Lecture) }
        (groups + lecture_rosters).each do |rosterable|
          service.remove_user!(@user, rosterable, notify: false, by: @user)
        end
      end

      def roster_entry_scopes
        [TutorialMembership.where(user: @user),
         SpeakerTalkJoin.where(speaker: @user),
         lecture_cohort_memberships,
         ExamRosterEntry.active.where(user: @user),
         LectureMembership.active.where(user: @user)]
      end

      # Groups in the order LectureLeave and the bulk self-service setting lock
      # them, so that leaving and giving up wait for each other.
      def rosterables
        Tutorial.where(id: TutorialMembership.where(user: @user).select(:tutorial_id))
                .order(:id).to_a +
          Cohort.where(id: lecture_cohort_memberships.select(:cohort_id)).order(:id).to_a +
          Talk.where(id: SpeakerTalkJoin.where(speaker: @user).select(:talk_id)).order(:id).to_a +
          Exam.where(id: ExamRosterEntry.active.where(user: @user).select(:exam_id)).to_a +
          Lecture.where(id: LectureMembership.active.where(user: @user).select(:lecture_id)).to_a
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
          .merge(Registration::Campaign.running)
      end

      def withdrawable_campaigns
        Registration::Campaign.running.where(
          id: Registration::UserRegistration.where(user: @user).select(:registration_campaign_id)
        )
      end
  end
end
