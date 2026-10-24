module Rosters
  # Brings the lecture rosters back in line with the places (see
  # LectureLeave.place?), for data from before enrollment followed them or
  # data that drifted since. Whoever is enrolled without a place is taken
  # off, as left without anybody's doing; their lists, registrations,
  # points and admission stay. Whoever is on an exam list without a place
  # is only reported: taking them off the lecture would take them off the
  # exam. The report also names registration campaigns that would go wrong
  # on their own, by their deadline or at the allocation.
  class EnrollmentReconciliation
    Row = Struct.new(:lecture, :enrolled, :without_place, :lists_only, :on_exam, :awaiting,
                     keyword_init: true)

    RUNNING = [:open, :closed, :processing].freeze
    FAR_DEADLINE = 8.weeks
    MANY_REGISTRATIONS = 20

    # `lecture_ids` narrows the reconciliation to some lectures, for a first
    # run on a few; nil means all.
    def initialize(lecture_ids: nil)
      @lecture_ids = lecture_ids
    end

    # One row per lecture with somebody enrolled without a place.
    def rows
      @rows ||= lectures.includes(:term, :course).order(:id).filter_map { |lecture| row(lecture) }
    end

    # Takes those without a place off, the ones on an exam list aside, and
    # returns how many it took off.
    def apply!
      rows.sum do |row|
        removable(row.lecture).each do |membership|
          ActiveRecord::Base.transaction do
            membership.exclude!
            membership.user.unbookmark_lecture!(row.lecture)
          end
        end.size
      end
    end

    def report
      lines = ["== Enrolled without a place"]
      lines += rows.map { |row| row_line(row) }
      lines << "== Running registration campaigns that go wrong on their own"
      lines += campaign_lines
      lines << "== Groups in a running campaign that hold members already"
      lines + member_lines
    end

    private

      def lectures
        scope = Lecture.where(id: LectureMembership.active.select(:lecture_id))
        @lecture_ids ? scope.where(id: @lecture_ids) : scope
      end

      def row(lecture)
        without = without_place(lecture)
        count = without.count
        return if count.zero?

        ids = without.select(:user_id)
        Row.new(lecture: lecture, enrolled: lecture.lecture_memberships.count,
                without_place: count,
                lists_only: CohortMembership.where(cohort: lists(lecture), user_id: ids)
                                            .distinct.count(:user_id),
                on_exam: on_exam(lecture, ids).distinct.count(:user_id),
                awaiting: awaiting(lecture, ids).distinct.count(:user_id))
      end

      def row_line(row)
        "#{row.lecture.id} #{row.lecture.title_term_info_no_type}: #{row.without_place} of " \
          "#{row.enrolled} without a place (#{row.lists_only} on a list only, " \
          "#{row.awaiting} awaiting a group, #{row.on_exam} on an exam list - kept)"
      end

      def without_place(lecture)
        place_user_ids(lecture).reduce(lecture.lecture_memberships) do |scope, ids|
          scope.where.not(user_id: ids)
        end
      end

      def removable(lecture)
        without = without_place(lecture)
        without.where.not(user_id: on_exam(lecture, without.select(:user_id)).select(:user_id))
               .includes(:user).to_a
      end

      def place_user_ids(lecture)
        [TutorialMembership.where(tutorial: lecture.tutorials).select(:user_id),
         SpeakerTalkJoin.where(talk: lecture.talks).select(:speaker_id),
         CohortMembership.where(cohort: lists(lecture, enrolling: true)).select(:user_id)]
      end

      def lists(lecture, enrolling: false)
        Cohort.where(context: lecture, propagate_to_lecture: enrolling)
      end

      def on_exam(lecture, user_ids)
        ExamRosterEntry.active.where(exam: lecture.exams, user_id: user_ids)
      end

      def awaiting(lecture, user_ids)
        campaigns = Registration::Campaign.non_exam.where(campaignable: lecture, status: RUNNING)
        Registration::UserRegistration.where(registration_campaign: campaigns,
                                             status: [:pending, :confirmed], user_id: user_ids)
      end

      def campaign_lines
        running_campaigns.includes(:campaignable, registration_items: :registerable)
                         .order(:id).filter_map { |campaign| campaign_line(campaign) }
      end

      def running_campaigns
        campaigns = Registration::Campaign.where(campaignable_type: "Lecture", status: RUNNING)
        @lecture_ids ? campaigns.where(campaignable_id: @lecture_ids) : campaigns
      end

      def campaign_line(campaign)
        flags = campaign_flags(campaign)
        return if flags.empty?

        lecture = campaign.campaignable
        title = campaign.description.presence || campaign.student_facing_title
        "#{lecture.id} #{lecture.title_term_info_no_type}, \"#{title}\" (#{campaign.status}): " \
          "#{flags.join("; ")}"
      end

      def campaign_flags(campaign)
        lecture = campaign.campaignable
        groups = campaign.registration_items.map(&:registerable)
        registered = campaign.user_registrations.where(status: [:pending, :confirmed])
        count = registered.count
        flags = []
        flags << "its term is over" if past_term?(lecture.term)
        flags << "allocated but never finalized" if campaign.processing?
        if campaign.registration_deadline&.after?(FAR_DEADLINE.from_now)
          flags << "deadline only on #{campaign.registration_deadline.to_date}"
        end
        clash = clashing(lecture, groups.grep(Tutorial), registered)
        flags << "#{clash} registered sit in another tutorial already" if clash.positive?
        if count >= MANY_REGISTRATIONS && groups.sum { |group| group.roster_entries.count }.zero?
          flags << "all groups empty with #{count} registrations"
        end
        flags
      end

      # Before the running term, that is; a campaign for the next term is
      # where registrations belong.
      def past_term?(term)
        @active_term = Term.active unless defined?(@active_term)
        term.present? && @active_term.present? && term.end_date < @active_term.begin_date
      end

      # An allocation would put them into a second tutorial of the lecture,
      # which a student cannot hold.
      def clashing(lecture, tutorials, registered)
        return 0 if tutorials.empty?

        TutorialMembership.where(tutorial: lecture.tutorials.where.not(id: tutorials))
                          .where(user_id: registered.select(:user_id))
                          .distinct.count(:user_id)
      end

      def member_lines
        Registration::Item.where(registration_campaign: running_campaigns)
                          .where.not(registerable_type: "Exam")
                          .includes(:registerable).filter_map do |item|
          group = item.registerable
          count = group.roster_entries.count
          "#{group.class.name} #{group.id} \"#{group.title}\": #{count} members" if count.positive?
        end
      end
  end
end
