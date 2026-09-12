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
        return if Demo::HandInSupport.manuscript_path.nil?

        assignments = demo_assignments(lecture).to_a
        handed_in = 0

        assignments.each_with_index do |assignment, index|
          sheets_left = assignments.size - index
          demo_teams(lecture).each_with_index do |(tutorial, team), position|
            team = team.reject { |member| sits_out?(assignment, member) }
            next if team.empty?
            next unless hands_in?(assignment, team)

            late = (handed_in % LATE_EVERY).zero?
            Demo::HandInSupport.hand_in!(
              assignment: assignment, tutorial: tutorial, team: team,
              correction: correction_for(sheets_left, position),
              handed_in_at: handed_in_at(assignment, late: late)
            )
            align_team_marks!(assignment, team)
            handed_in += 1
          end
        end
      end

      # HandInSupport would fill submitted_at for students recorded as missing.
      # A missing participation can also be recreated by AssessmentBackfillWorker
      # as pending, leaving that team member's status different from the others.
      def sits_out?(assignment, member)
        participation = assignment.assessment
                                  &.assessment_participations
                                  &.find_by(user_id: member.id)
        participation.nil? || participation.exempt? || participation.absent? ||
          participation.submitted_at.nil?
      end

      # A team is marked as one: the tutor enters the points once and every
      # member gets them (`SubmissionGraderService#enter_points_for_each_team_member!`).
      # The gradebook rolled its statuses and points per person before the
      # teams existed, so a pair could carry two verdicts; the marked member's
      # now stands for the team.
      def align_team_marks!(assignment, team)
        return if team.size < 2

        assessment = assignment.assessment
        return unless assessment

        participations = assessment.assessment_participations
                                   .where(user_id: team.map(&:id)).to_a
        marked = participations.find { |p| p.reviewed? && p.task_points.any? }
        return unless marked

        participations.each do |participation|
          next if participation == marked

          participation.task_points.delete_all
          marked.task_points.each do |point|
            participation.task_points.create!(task_id: point.task_id,
                                              points: point.points,
                                              grader_id: point.grader_id)
          end
          participation.update!(status: :reviewed,
                                graded_at: marked.graded_at,
                                grader_id: marked.grader_id,
                                points_total: marked.points_total)
        end
      end

      # On a sheet that is still open the gradebook has already decided who has
      # handed in: `randomize_demo_statuses!` keeps a participation for them and
      # drops it for the rest. Following that decision rather than handing in for
      # everybody is what keeps a file off a card the gradebook knows nothing
      # about - and it leaves both card states on the page to look at.
      def hands_in?(assignment, team)
        return true unless assignment.deadline.future?

        assessment = assignment.assessment
        return false unless assessment

        assessment.assessment_participations.exists?(user_id: team.first.id)
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

      # A submission counts as late by the hour it was written, and these are
      # written today while the deadlines are weeks past -- so every one of
      # them would be late. The hand-in is dated back behind the deadline
      # instead, except for every twentieth.
      #
      # Nothing can be late before its own deadline, and a sheet that is still
      # open was handed in at some point before now rather than around a date
      # that has not arrived.
      def handed_in_at(assignment, late:)
        return rand(2..72).hours.ago if assignment.deadline.future?
        return assignment.deadline + rand(1..48).hours if late

        assignment.deadline - rand(2..96).hours
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
