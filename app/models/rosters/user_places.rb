module Rosters
  # Collects where a student takes part: the rosters they are on and the
  # registrations still running. Rosters and exam lists show the student's
  # name and matriculation number, so a student with a place here may not
  # decline to give them, but may give up the places instead.
  class UserPlaces
    RUNNING_CAMPAIGN_STATUSES = [:open, :closed, :processing].freeze

    def initialize(user)
      @user = user
    end

    def any?
      roster_entry_scopes.any?(&:exists?) || running_registrations.exists?
    end

    # Names the lectures rather than every group, so that the student
    # recognizes them in one line.
    def lectures
      campaigns = Registration::Campaign.where(id: running_registrations
                                                     .select(:registration_campaign_id))
      (rosterables.map(&:lecture) + campaigns.map(&:campaignable))
        .grep(Lecture).uniq.sort_by(&:title)
    end

    # Withdraws the running registrations and leaves every roster, the
    # lectures last because leaving one takes its groups along. Raises
    # MaintenanceService::GradingDataPresentError, and gives up nothing, when
    # a talk or an exam already holds a result for the student.
    def give_up!
      service = MaintenanceService.new
      ActiveRecord::Base.transaction do
        running_registrations.destroy_all
        groups, lectures = rosterables.partition { |rosterable| !rosterable.is_a?(Lecture) }
        (groups + lectures).each { |rosterable| service.remove_user!(@user, rosterable) }
      end
    end

    private

      def roster_entry_scopes
        [TutorialMembership.where(user: @user),
         SpeakerTalkJoin.where(speaker: @user),
         CohortMembership.where(user: @user),
         ExamRosterEntry.active.where(user: @user),
         LectureMembership.where(user: @user)]
      end

      def rosterables
        Tutorial.where(id: TutorialMembership.where(user: @user).select(:tutorial_id)).to_a +
          Talk.where(id: SpeakerTalkJoin.where(speaker: @user).select(:talk_id)).to_a +
          Cohort.where(id: CohortMembership.where(user: @user).select(:cohort_id)).to_a +
          Exam.where(id: ExamRosterEntry.active.where(user: @user).select(:exam_id)).to_a +
          Lecture.where(id: LectureMembership.where(user: @user).select(:lecture_id)).to_a
      end

      def running_registrations
        Registration::UserRegistration
          .where(user: @user)
          .where.not(status: :rejected)
          .joins(:registration_campaign)
          .merge(Registration::Campaign.where(status: RUNNING_CAMPAIGN_STATUSES))
      end
  end
end
