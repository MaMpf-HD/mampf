module Rosters
  class LectureLeave
    Blocker = Struct.new(:reason, :title, :staff_can_help)

    GROUP_LOCK_ORDER = ["Tutorial", "Cohort", "Talk", "Exam"].freeze

    class NotAllowedError < StandardError; end
    class NotParticipatingError < StandardError; end

    def self.label(group)
      group.is_a?(Talk) ? group.to_label : group.title
    end

    def self.held_by_mode?(group)
      group.enrolls_in_lecture? && !group.is_a?(Exam)
    end

    def initialize(lecture, user)
      @lecture = lecture
      @user = user
    end

    # Whether the "Leave course" button is shown. Also shown when the student's
    # only tie to the lecture is a registration past its withdrawal deadline:
    # the registration card no longer offers to withdraw it, so leaving is the
    # only way out before the allocation.
    def participating?
      enrolled? || groups.any? || exam_entries.any? || registration_past_withdrawal?
    end

    def enrolled?
      return @enrolled if defined?(@enrolled)

      @enrolled = @lecture.lecture_memberships.exists?(user: @user)
    end

    def allowed?
      participating? && blockers.empty?
    end

    # Of the given members of the group, those for whom it is the last group
    # that keeps them in the lecture. Answers #only_place? for a whole roster at
    # once.
    def self.only_place_user_ids(group, user_ids)
      return [] unless group.enrolls_in_lecture?

      lecture = group.lecture
      return [] if lecture.nil? || user_ids.empty?

      member_ids = lecture.enrolling_memberships(user_ids)
                          .flat_map { |query| query.pluck(query.select_values.first) }
      single = member_ids.tally.filter_map { |id, count| id if count == 1 }
      return [] if single.empty?

      members = group.roster_entries.where(group.roster_user_id_column => single)
                     .select(group.roster_user_id_column)
      lecture.lecture_memberships.where(user_id: members).pluck(:user_id)
    end

    def places
      @places ||= groups.select(&:enrolls_in_lecture?) + exam_entries.map(&:exam)
    end

    # Whether the group is the student's last group that keeps them in the
    # lecture; leaving it ends the enrollment.
    def only_place?(group)
      enrolled? && places == [group]
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

    # When an exam or talk is already graded, only that is listed as a blocker.
    # The staff could lift the other blockers, but not this one.
    def blockers
      @blockers ||= graded_blockers.presence ||
                    (held_group_blockers + closed_exam_blockers + prerequisite_blockers)
    end

    # What keeps the student in their last group: a result, or an exam
    # registration past its withdrawal deadline. Leaving only that group keeps
    # lists and registrations, so nothing else of #blockers applies.
    def last_place_blockers
      @last_place_blockers ||= graded_blockers.presence || closed_exam_blockers
    end

    # The flexible groups without enrollment the student is in. They stay when
    # the last group with enrollment goes.
    def lists
      groups.reject(&:enrolls_in_lecture?)
    end

    # The lecture's running campaigns the student is registered in. They stay
    # when the last group with enrollment goes, and leaving the lecture
    # withdraws them.
    def running_campaigns
      @running_campaigns ||= begin
        registered = Registration::UserRegistration.where(user: @user)
                                                   .where.not(status: :rejected)
        Registration::Campaign.running
                              .where(campaignable: @lecture,
                                     id: registered.select(:registration_campaign_id))
                              .order(:registration_deadline)
      end
    end

    def bookmarked?
      LectureBookmark.exists?(lecture: @lecture, user: @user)
    end

    def campaigns_to_withdraw
      @campaigns_to_withdraw ||= running_campaigns.to_a - closed_exam_campaigns
    end

    def admitted?
      StudentPerformance::Certification.passed.exists?(lecture: @lecture, user: @user)
    end

    # The dialog checked without locks; this checks again under the locks, on
    # a new instance because this one has cached the earlier answer. If a
    # result was entered in between, the removal fails, which also raises
    # NotAllowedError. A deadlock is retried once.
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

      # Locks the lecture's unfinished campaigns first, drafts included: a draft
      # opened meanwhile could take a new registration from the student that
      # leaving would miss. Then the groups and exams, then the lecture.
      def lock_places!
        Registration::Campaign.where(campaignable: @lecture)
                              .where.not(status: :completed)
                              .order(:id).lock.load
        (groups + exam_entries.map(&:exam))
          .sort_by { |group| [GROUP_LOCK_ORDER.index(group.class.name), group.id] }
          .each(&:lock!)
        @lecture.lock!
      end

      def graded_blockers
        graded_talks.map { |talk| Blocker.new(:graded, self.class.label(talk), false) } +
          exam_entries.select { |entry| entry.exam_id.in?(graded_exam_ids) }
                      .map { |entry| Blocker.new(:graded, entry.exam.title, false) }
      end

      def held_group_blockers
        groups.select { |group| self.class.held_by_mode?(group) }
              .select { |group| held?(group) && !group.in?(graded_talks) }
              .map { |group| Blocker.new(:group_held, self.class.label(group), true) }
      end

      def held?(group)
        !group.allow_self_remove?(@user) || group.in_running_campaign?
      end

      def closed_exam_blockers
        exam_entries.reject { |entry| entry.exam_id.in?(graded_exam_ids) }
                    .map { |entry| Blocker.new(:exam_closed, entry.exam.title, true) } +
          closed_exam_campaigns.map do |campaign|
            Blocker.new(:exam_closed, campaign.student_facing_title, true)
          end
      end

      # Blocks when the student is confirmed in another lecture's campaign that
      # requires their registration here, e.g. a seminar that requires this
      # lecture. Withdrawing that registration on its own is refused as well.
      def prerequisite_blockers
        withdrawn = Registration::Campaign.running.where(
          campaignable: @lecture,
          id: Registration::UserRegistration.where(user: @user).select(:registration_campaign_id)
        )
        requiring = withdrawn.pluck(:id).flat_map do |campaign_id|
          Registration::Policy.prerequisite_campaign.referencing_campaign(campaign_id)
                              .pluck(:registration_campaign_id)
        end
        return [] if requiring.empty?

        confirmed = Registration::UserRegistration.confirmed.where(user: @user)
        Registration::Campaign.where(id: requiring)
                              .where(id: confirmed.select(:registration_campaign_id))
                              .where.not(campaignable: @lecture)
                              .map do |campaign|
          Blocker.new(:prerequisite, campaign.student_facing_title, true)
        end
      end

      # Whether the student has a registration here whose withdrawal deadline
      # has passed. Rejected ones count too: a new allocation can still give
      # them a place.
      def registration_past_withdrawal?
        registered = Registration::UserRegistration.where(user: @user)
        Registration::Campaign.running
                              .where(campaignable: @lecture,
                                     id: registered.select(:registration_campaign_id))
                              .any? { |campaign| !campaign.open_for_withdrawals? }
      end

      def exam_entries
        @exam_entries ||= ExamRosterEntry.active
                                         .where(user: @user, exam: @lecture.exams)
                                         .includes(:exam).to_a
      end

      # The lecture's talks with a result for the student, whether or not they
      # are still a speaker there. Any such result keeps them from being
      # removed from the lecture.
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

      # The exam campaigns the student is registered in whose withdrawal
      # deadline has passed. Checks the deadline rather than the status,
      # because CampaignStatusWorker closes a campaign only on its next run.
      def closed_exam_campaigns
        @closed_exam_campaigns ||= running_campaigns.exam.reject(&:open_for_withdrawals?)
      end
  end
end
