module Demo
  # The lecture's own sheets are handed in without an assessment behind them,
  # which is the old way. The demo homework has one -- tasks, points, a status
  # per participant -- and needed a stack of real hand-ins under it, so that
  # the correction and grading views have something to show.
  module HomeworkSubmissionSupport
    # One pair per tutorial, everybody else alone -- which is what a tutorial
    # looks like, and it keeps the teams inside what the lecture allows.
    TEAMS_WITH_A_PARTNER = 1
    # The last sheets are the ones the tutor has not got to yet.
    UNCORRECTED_SHEETS = 2
    # Handing in after the deadline happens, but rarely.
    LATE_EVERY = 20

    def setup_homework_submissions!
      lecture = assessment_lecture!

      Rails.logger.debug("=== Demo Homework Submissions ===")
      Demo::QuietLoggingSupport.with_quiet_logging do
        reset_demo_submissions!(lecture)
        hand_in_demo_homework!(lecture)
      end
      report_demo_submissions(lecture)
      Rails.logger.debug("=== Demo Homework Submissions Complete ===")
    end

    private

      def reset_demo_submissions!(lecture)
        Submission.where(assignment: demo_assignments(lecture)).find_each(&:destroy)
      end

      def hand_in_demo_homework!(lecture)
        return if demo_manuscript_path.nil?

        assignments = demo_assignments(lecture).to_a
        handed_in = 0

        assignments.each_with_index do |assignment, index|
          sheets_left = assignments.size - index
          demo_teams(lecture).each_with_index do |(tutorial, team), position|
            hand_in_demo!(assignment, tutorial, team,
                          correction: correction_for(sheets_left, position),
                          late: (handed_in % LATE_EVERY).zero?)
            handed_in += 1
          end
        end

        recompute_performance_records!(lecture)
      end

      # `record_hand_in!` stamps with `update_all`, which is what keeps the run
      # quick and what skips the callback behind it. The materialized record
      # counts a sheet as awaiting marks by its `submitted_at`, so without this
      # the standing block ends up disagreeing with the list beneath it.
      def recompute_performance_records!(lecture)
        service = StudentPerformance::ComputationService.new(lecture: lecture)
        lecture.members.find_each { |member| service.compute_and_upsert_record_for(member) }
      end

      # The tutor is behind by the last couple of sheets, and one team in three
      # is still waiting on the ones before them.
      def correction_for(sheets_left, position)
        return if sheets_left <= UNCORRECTED_SHEETS
        return if position % 3 == 2

        position.even? ? :accepted : :pending
      end

      def demo_teams(lecture)
        @demo_teams ||= {}
        @demo_teams[lecture.id] ||=
          staffed_tutorials(lecture).flat_map do |tutorial|
            members = tutorial.tutorial_memberships.includes(:user)
                              .map(&:user).sort_by(&:id)
            pair = members.first(TEAMS_WITH_A_PARTNER * 2)
            teams = [pair] + members.drop(pair.size).zip
            teams.reject(&:empty?).map { |team| [tutorial, team] }
          end
      end

      def hand_in_demo!(assignment, tutorial, team, correction:, late:)
        submission = Submission.new(assignment: assignment, tutorial: tutorial,
                                    users: [team.first])
        submission.manuscript = demo_manuscript_copy
        submission.save!
        stamp_hand_in!(submission, assignment, late: late)
        # A partner joins the existing submission; handing both to a new one
        # trips the team-size check, which counts what is already in the team.
        team.drop(1).each do |partner|
          UserSubmissionJoin.create!(user: partner, submission: submission)
        end
        record_hand_in!(assignment, team, submission)
        return unless correction

        submission.correction = demo_manuscript_copy
        submission.accepted = correction == :accepted
        submission.save!
      end

      # What the controller does on every upload: the gradebook learns that the
      # sheet was handed in. Without it the demo builds a state that is real but
      # rare - a file on record with no hand-in against it, which the student's
      # page has to flag in red - and builds it by the dozen.
      #
      # Only the stamp, and only where it is missing: the statuses and points
      # were dealt beforehand and are what the demo is for.
      def record_hand_in!(assignment, team, submission)
        participations = assignment.assessment&.assessment_participations
        return unless participations

        handed_in_at = submission.last_modification_by_users_at
        # rubocop:disable Rails/SkipsModelValidations
        participations.where(user_id: team.map(&:id), submitted_at: nil)
                      .update_all(submitted_at: handed_in_at,
                                  updated_at: Time.current)
        # rubocop:enable Rails/SkipsModelValidations
      end

      # A submission counts as late by the hour it was written, and these are
      # written today while the deadlines are weeks past -- so every one of them
      # would be late. The hand-in is dated back behind the deadline instead,
      # except for every twentieth.
      def stamp_hand_in!(submission, assignment, late:)
        handed_in_at = if late
          assignment.deadline + rand(1..48).hours
        else
          assignment.deadline - rand(2..96).hours
        end
        # rubocop:disable Rails/SkipsModelValidations
        submission.update_columns(created_at: handed_in_at,
                                  last_modification_by_users_at: handed_in_at)
        # rubocop:enable Rails/SkipsModelValidations
      end

      # One copy on disk, opened again per hand-in, because Shrine closes what
      # it has uploaded.
      def demo_manuscript_path
        return @demo_manuscript_path if defined?(@demo_manuscript_path)

        source = Medium.where.not(manuscript_data: nil)
                       .min_by { |medium| medium.manuscript.size.to_i }
        @demo_manuscript_path = source && write_demo_copy(source.manuscript.download)
      end

      def write_demo_copy(download)
        path = File.join(Dir.mktmpdir, "abgabe.pdf")
        File.binwrite(path, download.read)
        path
      end

      def demo_manuscript_copy
        demo_manuscript_path && File.open(demo_manuscript_path, "rb")
      end

      def report_demo_submissions(lecture)
        submissions = Submission.where(assignment: demo_assignments(lecture))
        Rails.logger.debug do
          "#{submissions.count} demo submissions, " \
            "#{submissions.where.not(correction_data: nil).count} of them corrected."
        end
      end
  end
end
