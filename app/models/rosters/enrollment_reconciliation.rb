module Rosters
  # Brings the rosters of the active and the next term's lectures in line with
  # the places: takes out the students enrolled without a group that enrolls
  # them (see Rosters::Rosterable#enrolls_in_lecture?), and enrolls those who
  # hold a place without being enrolled. The report also lists running
  # campaigns with problems of their own, e.g. never finalized, or an
  # allocation that would move students out of their tutorial.
  #
  # TODO: Remove together with lib/tasks/enrollment.rake once it has run on
  # production (#1408, https://github.com/MaMpf-HD/mampf/pull/1408).
  class EnrollmentReconciliation
    Row = Struct.new(:lecture, :enrolled, :without_place, :lists_only, :awaiting, :with_results,
                     :staff, :missing, keyword_init: true)

    FAR_DEADLINE = 8.weeks
    MANY_REGISTRATIONS = 20

    # lecture_ids limits the run to these lectures, e.g. to try it on a few
    # first; nil means all of the active and the next term.
    def initialize(lecture_ids: nil)
      @lecture_ids = lecture_ids
    end

    def rows
      @rows ||= lectures.includes(:term, :course).order(:id).filter_map { |lecture| row(lecture) }
    end

    # Excludes who is enrolled without a place, with excluded_by left empty,
    # and enrolls who has a place without a membership. Their bookmark goes
    # unless they are still in a flexible group without enrollment of the
    # lecture. Decides under each lecture's lock, which every change to such a
    # group takes too, so none is missed. Leaves a lecture where nobody has a
    # place alone. Returns how many it excluded and how many it enrolled.
    def apply!
      rows.reject { |row| nobody_placed?(row) }.reduce([0, 0]) do |(excluded, enrolled), row|
        row.lecture.with_lock do
          [excluded + exclude!(row.lecture), enrolled + enroll!(row.lecture)]
        end
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
        active = Term.active
        scope = Lecture.where(term: [active, active&.next].compact)
        @lecture_ids ? scope.where(id: @lecture_ids) : scope
      end

      def row(lecture)
        without = without_place(lecture)
        count = without.count
        missing = missing_ids(lecture)
        return if count.zero? && missing.empty?

        ids = without.pluck(:user_id)
        Row.new(lecture: lecture, enrolled: lecture.lecture_memberships.count,
                without_place: count,
                lists_only: CohortMembership.where(cohort: lists(lecture), user_id: ids)
                                            .distinct.count(:user_id),
                awaiting: awaiting_ids(lecture, ids).size,
                with_results: with_results_ids(lecture, ids).size,
                staff: (ids & staff_ids(lecture)).size,
                missing: missing.size)
      end

      def row_line(row)
        line = "#{row.lecture.id} #{row.lecture.title_term_info_no_type}: #{row.without_place} " \
               "of #{row.enrolled} without a place (#{row.lists_only} on a list only, " \
               "#{row.with_results} with a hand-in, points, a result or an admission; " \
               "kept: #{row.awaiting} awaiting a place, #{row.staff} staff), " \
               "#{row.missing} with a place but not enrolled"
        nobody_placed?(row) ? "#{line} -- nobody has a place, left alone" : line
      end

      # A lecture whose students all lack a place has no groups in use; taking
      # them all out is not what it needs, a cohort with enrollment is.
      def nobody_placed?(row)
        row.without_place.positive? && row.without_place == row.enrolled
      end

      def exclude!(lecture)
        memberships = removable(lecture)
        listed = Cohort.lists_by_user(lecture, memberships.map(&:user_id))
        memberships.each do |membership|
          membership.exclude!
          next if listed.key?(membership.user_id)

          membership.user.unbookmark_lecture!(lecture)
        end.size
      end

      def enroll!(lecture)
        ids = missing_ids(lecture)
        lecture.ensure_roster_membership!(ids) if ids.any?
        ids.size
      end

      def without_place(lecture)
        lecture.enrolling_memberships.reduce(lecture.lecture_memberships) do |scope, memberships|
          scope.where.not(user_id: memberships)
        end
      end

      # Keeps the lecture's staff, who are not its students, and whoever waits
      # in a running campaign, so that an allocation without a place for them
      # shows them as unassigned rather than as left. Whoever has a hand-in,
      # points, a result or an admission goes too and keeps them, as when the
      # staff take someone out of their last group.
      def removable(lecture)
        without = without_place(lecture)
        kept = staff_ids(lecture) + awaiting_ids(lecture, without.pluck(:user_id))
        without.where.not(user_id: kept).includes(:user).to_a
      end

      def missing_ids(lecture)
        placed = lecture.enrolling_memberships
                        .flat_map { |query| query.pluck(query.select_values.first) }.uniq
        placed - lecture.lecture_memberships.where(user_id: placed).pluck(:user_id)
      end

      # Teacher, editors and tutors of the lecture. Counts tutors as
      # Lecture#tutor? does, including those who redeemed a tutor voucher, plus
      # the tutors of its cohorts.
      def staff_ids(lecture)
        ([lecture.teacher_id] + lecture.editor_ids + lecture.course.editor_ids +
          TutorTutorialJoin.where(tutorial: lecture.tutorials).pluck(:tutor_id) +
          TutorAppointment.where(lecture: lecture).pluck(:user_id) +
          Redemption.where(voucher: lecture.vouchers.for_tutors).pluck(:user_id) +
          CohortTutorJoin.where(cohort: lecture.cohorts).pluck(:tutor_id)).compact.uniq
      end

      def with_results_ids(lecture, user_ids)
        graded = Assessment::Participation.with_recorded_work.joins(:assessment)
                                          .where(assessment_assessments: { lecture_id: lecture.id },
                                                 user_id: user_ids)
                                          .distinct.pluck(:user_id)
        certified = StudentPerformance::Certification.where(lecture: lecture, user_id: user_ids)
                                                     .pluck(:user_id)
        (graded + certified).uniq
      end

      def lists(lecture)
        Cohort.where(context: lecture, propagate_to_lecture: false)
      end

      def awaiting_ids(lecture, user_ids)
        campaigns = Registration::Campaign.running.where(campaignable: lecture)
        Registration::UserRegistration.where(registration_campaign: campaigns,
                                             status: [:pending, :confirmed], user_id: user_ids)
                                      .distinct.pluck(:user_id)
      end

      def campaign_lines
        running_campaigns.includes(:campaignable, registration_items: :registerable)
                         .order(:id).filter_map { |campaign| campaign_line(campaign) }
      end

      def running_campaigns
        campaigns = Registration::Campaign.running.where(campaignable_type: "Lecture")
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
        if campaign.closed? && campaign.registration_deadline&.before?(FAR_DEADLINE.ago)
          flags << "closed since #{campaign.registration_deadline.to_date}, never finalized"
        end
        if campaign.registration_deadline&.after?(FAR_DEADLINE.from_now)
          flags << "deadline only on #{campaign.registration_deadline.to_date}"
        end
        clash = clashing(lecture, groups.grep(Tutorial), registered)
        flags << "#{clash} registered would be moved out of their tutorial" if clash.positive?
        if count >= MANY_REGISTRATIONS && groups.sum { |group| group.roster_entries.count }.zero?
          flags << "all groups empty with #{count} registrations"
        end
        flags
      end

      # Whether the term ended before the active term began, so that a campaign
      # for the next term is not flagged.
      def past_term?(term)
        @active_term = Term.active unless defined?(@active_term)
        term.present? && @active_term.present? && term.end_date < @active_term.begin_date
      end

      # Counts registered students who already sit in another tutorial of the
      # lecture. The allocation would move them out of it, because
      # Tutorial#persist_missing_roster_entries! upserts on user and lecture.
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
