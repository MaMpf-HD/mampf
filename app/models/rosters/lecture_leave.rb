module Rosters
  # Ends a student's participation in a whole lecture, all or nothing;
  # recorded points stay for a later return.
  class LectureLeave
    # `reason` names the locale key, `title` the group, exam or campaign
    # concerned, and `contact` whether the lecture's staff can still help.
    Blocker = Struct.new(:reason, :title, :contact)

    # Tutorials, then cohorts, then talks, each by id: the order the bulk
    # self-service setting and UserPlaces take them in.
    GROUP_LOCK_ORDER = ["Tutorial", "Cohort", "Talk"].freeze

    class NotAllowedError < StandardError; end
    class NotParticipatingError < StandardError; end

    # Talks go by their label, which carries the number, as elsewhere in the
    # participation list.
    def self.label(group)
      group.is_a?(Talk) ? group.to_label : group.title
    end

    # The Unicode white space characters, listed out so that
    # leave_confirmation.controller.js can match exactly the same ones.
    SPACES = /[\t\n\v\f\r \u0085\u00A0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000\uFEFF]+/

    # Upcases rather than downcases: both Ruby and JavaScript upcase without
    # regard to the neighbouring letters, which lowercasing a final sigma does.
    def self.normalize(text)
      text.to_s.gsub(SPACES, "").upcase
    end

    def initialize(lecture, user)
      @lecture = lecture
      @user = user
    end

    def participating?
      enrolled? || groups.any? || exam_entries.any?
    end

    def enrolled?
      return @enrolled if defined?(@enrolled)

      @enrolled = @lecture.lecture_memberships.exists?(user: @user)
    end

    def allowed?
      participating? && blockers.empty?
    end

    # What the student types to confirm: the course's short title, as the
    # name of what is left, without spaces, which are easy to miss.
    def confirmation_code
      @lecture.course.short_title.gsub(SPACES, "")
    end

    def confirmed?(input)
      self.class.normalize(input) == self.class.normalize(confirmation_code)
    end

    def groups
      @groups ||=
        Tutorial.where(lecture: @lecture,
                       id: TutorialMembership.where(user: @user).select(:tutorial_id))
                .order(:title).to_a +
        Talk.where(lecture: @lecture,
                   id: SpeakerTalkJoin.where(speaker: @user).select(:talk_id))
            .order(:position).to_a +
        Cohort.where(context: @lecture,
                     id: CohortMembership.where(user: @user).select(:cohort_id))
              .order(:title).to_a
    end

    # While a graded exam or talk blocks, the other blockers are not named:
    # the lecture's staff could lift them, but leaving would stay refused.
    def blockers
      @blockers ||= graded_blockers.presence ||
                    (fixed_group_blockers + closed_exam_blockers)
    end

    # The campaigns the dialog names. A rejected registration is withdrawn
    # too (see UserPlaces#leave!), but not named: to the student it is no
    # registration they give up.
    def campaigns_to_withdraw
      @campaigns_to_withdraw ||= running_campaigns.to_a - closed_exam_campaigns
    end

    # The granted exam admission, :computed or :manual. It goes with the
    # LectureMembership, whose removal deletes the Certification.
    def admission
      StudentPerformance::Certification.passed
                                       .find_by(lecture: @lecture, user: @user)
                                       &.source&.to_sym
    end

    # Decides again under the locks on a fresh instance, since this one
    # memoizes its blockers. Grading data found during the removal raises
    # NotAllowedError too; an ActiveRecord::Deadlocked that aborted this
    # transaction is retried once.
    def leave!
      attempts = 0
      begin
        attempts += 1
        ActiveRecord::Base.transaction do
          lock_places!
          fresh = self.class.new(@lecture, @user)
          raise(NotParticipatingError) unless fresh.participating?
          raise(NotAllowedError) unless fresh.allowed?

          UserPlaces.new(@user).leave!([@lecture])
          @user.unbookmark_lecture!(@lecture)
        end
      rescue ActiveRecord::Deadlocked
        retry if attempts < 2
        raise
      end
    rescue MaintenanceService::GradingDataPresentError,
           Talk::SpeakerRemovalNotAllowedError,
           Exam::ParticipantRemovalNotAllowedError
      raise(NotAllowedError)
    end

    private

      # Campaigns first, drafts too so none opens meanwhile, as allocation
      # does; the groups before the lecture, as a group's update touching the
      # lecture does; the lecture before any membership goes, as the staff's
      # removal does. Reordering talks and the self-service setting after
      # finalization lock groups in their own order; a deadlock with them
      # aborts one side, and only leaving tries again.
      def lock_places!
        Registration::Campaign.where(campaignable: @lecture)
                              .where.not(status: :completed)
                              .order(:id).lock.load
        groups.sort_by { |group| [GROUP_LOCK_ORDER.index(group.class.name), group.id] }
              .each(&:lock!)
        @lecture.lock!
      end

      def graded_blockers
        graded_talks.map { |talk| Blocker.new(:graded, self.class.label(talk), false) } +
          exam_entries.select { |entry| entry.exam_id.in?(graded_exam_ids) }
                      .map { |entry| Blocker.new(:graded, entry.exam.title, false) }
      end

      def fixed_group_blockers
        groups.select { |group| fixed?(group) && !group.in?(graded_talks) }
              .map { |group| Blocker.new(:group_fixed, self.class.label(group), true) }
      end

      # A tutorial's or cohort's self-service mode is about moving within the
      # lecture, so only a running campaign holds it; a talk is a commitment
      # to the seminar's schedule and keeps its own setting.
      def fixed?(group)
        return !group.allow_self_remove?(@user) if group.is_a?(Talk)

        group.registration_items
             .joins(:registration_campaign)
             .merge(Registration::Campaign.where(status: UserPlaces::RUNNING_CAMPAIGN_STATUSES))
             .exists?
      end

      # An exam list or an exam registration past its deadline: withdrawing
      # from an exam is up to the lecture's staff then.
      def closed_exam_blockers
        exam_entries.reject { |entry| entry.exam_id.in?(graded_exam_ids) }
                    .map { |entry| Blocker.new(:exam_closed, entry.exam.title, true) } +
          closed_exam_campaigns.map do |campaign|
            Blocker.new(:exam_closed, campaign.student_facing_title, true)
          end
      end

      def exam_entries
        @exam_entries ||= ExamRosterEntry.active
                                         .where(user: @user, exam: @lecture.exams)
                                         .includes(:exam).to_a
      end

      # Every graded talk of the lecture, not only those the user speaks in:
      # leaving the lecture roster refuses on any of them.
      def graded_talks
        @graded_talks ||= @lecture.talks.where(id: graded_assessable_ids(@lecture.talks)).to_a
      end

      def graded_exam_ids
        @graded_exam_ids ||= graded_assessable_ids(@lecture.exams)
      end

      def graded_assessable_ids(assessables)
        graded = Assessment::Participation.with_grading_data.where(user: @user)
        Assessment::Assessment.where(assessable: assessables,
                                     id: graded.select(:assessment_id))
                              .pluck(:assessable_id)
      end

      def running_campaigns
        registered = Registration::UserRegistration.where(user: @user)
                                                   .where.not(status: :rejected)
        Registration::Campaign.where(campaignable: @lecture,
                                     status: UserPlaces::RUNNING_CAMPAIGN_STATUSES,
                                     id: registered.select(:registration_campaign_id))
                              .order(:registration_deadline)
      end

      # By the deadline, not the status alone: CampaignStatusWorker closes a
      # campaign only on its next run.
      def closed_exam_campaigns
        @closed_exam_campaigns ||= running_campaigns.exam.reject(&:open_for_withdrawals?)
      end
  end
end
