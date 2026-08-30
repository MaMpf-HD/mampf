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
        assignments.each_with_index do |assignment, index|
          sheets_left = assignments.size - index
          demo_teams(lecture).each_with_index do |(tutorial, team), position|
            hand_in_demo!(assignment, tutorial, team,
                          correction: correction_for(sheets_left, position))
          end
        end
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

      def hand_in_demo!(assignment, tutorial, team, correction:)
        submission = Submission.new(assignment: assignment, tutorial: tutorial,
                                    users: [team.first])
        submission.manuscript = demo_manuscript_copy
        submission.save!
        # A partner joins the existing submission; handing both to a new one
        # trips the team-size check, which counts what is already in the team.
        team.drop(1).each do |partner|
          UserSubmissionJoin.create!(user: partner, submission: submission)
        end
        return unless correction

        submission.correction = demo_manuscript_copy
        submission.accepted = correction == :accepted
        submission.save!
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
