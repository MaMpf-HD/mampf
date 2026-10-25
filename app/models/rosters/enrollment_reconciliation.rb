module Rosters
  # Brings the lecture rosters in line with the places (see
  # Rosters::Rosterable#place?), for data from before enrollment followed
  # them. The report also names campaigns that would go wrong on their own.
  class EnrollmentReconciliation
    Row = Struct.new(:lecture, :enrolled, :without_place, :lists_only, :awaiting, :admitted,
                     :staff, keyword_init: true)

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

    # Excludes whoever is enrolled without a place, excluded_by left empty,
    # and removes their bookmark; lists, registrations, points and admission
    # stay. Decides under each lecture's lock, which every change to a place
    # takes too. Returns how many it excluded.
    def apply!
      rows.sum do |row|
        row.lecture.with_lock do
          removable(row.lecture).each do |membership|
            membership.exclude!
            membership.user.unbookmark_lecture!(row.lecture)
          end.size
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
                awaiting: awaiting(lecture, ids).distinct.count(:user_id),
                admitted: admitted(lecture, removable(lecture).map(&:user_id)).count,
                staff: without.where(user_id: staff_ids(lecture)).count)
      end

      def row_line(row)
        "#{row.lecture.id} #{row.lecture.title_term_info_no_type}: #{row.without_place} of " \
          "#{row.enrolled} without a place (#{row.lists_only} on a list only, " \
          "#{row.awaiting} awaiting a place, #{row.admitted} admitted; kept: " \
          "#{row.staff} staff)"
      end

      def without_place(lecture)
        place_user_ids(lecture).reduce(lecture.lecture_memberships) do |scope, ids|
          scope.where.not(user_id: ids)
        end
      end

      # The lecture's staff are not its students.
      def removable(lecture)
        without_place(lecture).where.not(user_id: staff_ids(lecture)).includes(:user).to_a
      end

      def place_user_ids(lecture)
        lecture.place_user_id_queries
      end

      def staff_ids(lecture)
        ([lecture.teacher_id] + lecture.editor_ids + lecture.course.editor_ids +
          TutorTutorialJoin.where(tutorial: lecture.tutorials).pluck(:tutor_id) +
          TutorAppointment.where(lecture: lecture).pluck(:user_id)).compact.uniq
      end

      def admitted(lecture, user_ids)
        StudentPerformance::Certification.passed.where(lecture: lecture, user_id: user_ids)
      end

      def lists(lecture)
        Cohort.where(context: lecture, propagate_to_lecture: false)
      end

      def awaiting(lecture, user_ids)
        campaigns = Registration::Campaign.where(campaignable: lecture, status: RUNNING)
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

      # Whether the term ended before the active one began; a campaign of the
      # next term is not stale.
      def past_term?(term)
        @active_term = Term.active unless defined?(@active_term)
        term.present? && @active_term.present? && term.end_date < @active_term.begin_date
      end

      # An allocation moves them out of the tutorial they sit in, since
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
