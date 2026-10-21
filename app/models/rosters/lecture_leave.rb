module Rosters
  # Ends a student's participation in one lecture from its home page: the
  # groups and the lecture roster are left, running registrations withdrawn
  # and the bookmark removed. Points stay recorded, so they are back when the
  # student joins again. What the student may not undo alone blocks the whole
  # step: a group whose staff do not let members leave, an exam list once its
  # registration has closed, and a graded exam or talk.
  class LectureLeave
    # `reason` names the locale key, `title` the group, exam or campaign
    # concerned, and `contact` whether the lecture's staff can still help.
    Blocker = Struct.new(:reason, :title, :contact)

    # Raised when the student may not leave the lecture, see #blockers.
    class NotAllowedError < StandardError; end

    # A talk's own title may be empty; its label carries the number.
    def self.label(group)
      group.is_a?(Talk) ? group.to_label : group.title
    end

    def initialize(lecture, user)
      @lecture = lecture
      @user = user
    end

    # Whether the user has a place in the lecture to give up: its roster, one
    # of its groups or an exam list.
    def participating?
      LectureMembership.exists?(lecture: @lecture, user: @user) ||
        groups.any? || exam_entries.any?
    end

    def allowed?
      participating? && blockers.empty?
    end

    # What the student types to confirm: the course's short title, as the
    # name of what is left, without spaces, which are easy to miss.
    def confirmation_code
      @lecture.course.short_title.gsub(/\s+/, "")
    end

    def confirmed?(input)
      input.to_s.gsub(/\s+/, "").casecmp?(confirmation_code)
    end

    # The tutorials, talks and cohorts of the lecture the user is in.
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

    # A graded exam or talk rules out leaving for good, so the others, which
    # the lecture's staff could lift, are not named next to it.
    def blockers
      @blockers ||= graded_blockers.presence ||
                    (fixed_group_blockers + closed_exam_blockers)
    end

    # The campaigns whose registrations leaving withdraws.
    def withdrawn_campaigns
      @withdrawn_campaigns ||= running_campaigns.where.not(id: closed_exam_campaigns)
                                                .to_a
    end

    # :computed or :manual for a granted exam admission, which ends with the
    # roster seat; nil when there is none.
    def admission
      StudentPerformance::Certification.passed
                                       .find_by(lecture: @lecture, user: @user)
                                       &.source&.to_sym
    end

    # Raises NotAllowedError when a blocker stands in the way, and then
    # changes nothing.
    def leave!
      ActiveRecord::Base.transaction do
        raise(NotAllowedError) unless allowed?

        UserPlaces.new(@user).leave!([@lecture])
        @user.unbookmark_lecture!(@lecture)
      end
    end

    private

      def graded_blockers
        graded_talks.map { |talk| Blocker.new(:graded, self.class.label(talk), false) } +
          exam_entries.select { |entry| entry.exam_id.in?(graded_exam_ids) }
                      .map { |entry| Blocker.new(:graded, entry.exam.title, false) }
      end

      def fixed_group_blockers
        groups.reject { |group| group.allow_self_remove?(@user) || group.in?(graded_talks) }
              .map { |group| Blocker.new(:group_fixed, self.class.label(group), true) }
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

      def closed_exam_campaigns
        @closed_exam_campaigns ||= running_campaigns.exam.where.not(status: :open).to_a
      end
  end
end
