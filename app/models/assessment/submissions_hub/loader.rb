module Assessment
  module SubmissionsHub
    # Everything /lectures/:id/submissions needs about one person, fetched in one
    # go. The page shows a row and a fold per sheet plus the exam-admission block,
    # and all of them want the same handful of associations - asked for per sheet
    # that is an N+1 the moment a lecture runs a dozen of them, which is why the
    # page it replaces needed 159 queries for what this answers in a fixed number
    # that does not grow with the sheet count.
    #
    # The loader knows no views and what it returns knows no database; that seam
    # is where the specs sit.
    class Loader
      def initialize(lecture:, user:)
        @lecture = lecture
        @user = user
      end

      def call
        Result.new(sheets: sheets, standing: standing, open_sheets: open_sheets,
                   due: due, latest_marked: latest_marked)
      end

      private

        attr_reader :lecture, :user

        def sheets
          @sheets ||= assignments.map { |assignment| build_sheet(assignment) }
        end

        def build_sheet(assignment)
          assessment = assignment.assessment
          participation = assessment && participations[assessment.id]
          submission = submissions[assignment.id]
          # `Submission#too_late?` reads its assignment's deadline, and that is the
          # assignment in hand. Without this it would be fetched again per sheet.
          submission&.assignment = assignment

          Sheet.new(assignment: assignment, assessment: assessment,
                    participation: participation, submission: submission,
                    tasks: sorted_tasks(assessment),
                    points_by_task_id: task_points_by_task_id(participation),
                    user: user)
        end

        # `tasks.order(:position)` would go back to the database for a list that is
        # already loaded, once per sheet.
        def sorted_tasks(assessment)
          return [] unless assessment

          assessment.tasks.sort_by { |task| task.position || 0 }
        end

        def task_points_by_task_id(participation)
          return {} unless participation

          participation.task_points.index_by(&:task_id)
        end

        def assignments
          @assignments ||= lecture.assignments
                                  .includes(assessment: :tasks)
                                  .order(deadline: :desc)
                                  .to_a
        end

        def assessment_ids
          @assessment_ids ||= assignments.filter_map { |a| a.assessment&.id }
        end

        # `task_points` rather than `task_points: :task`: the tasks already hang on
        # the assessment, and asking for them again here costs three more queries.
        # The graders come along because the fold names who marked the sheet.
        def participations
          @participations ||=
            if assessment_ids.empty?
              {}
            else
              Participation
                .where(assessment_id: assessment_ids, user_id: user.id)
                .includes(:grader, task_points: :grader)
                .index_by(&:assessment_id)
            end
        end

        def submissions
          @submissions ||=
            if assignments.empty?
              {}
            else
              Submission.joins(:user_submission_joins)
                        .where(user_submission_joins: { user_id: user.id },
                               assignment_id: assignments.map(&:id))
                        .includes(:users)
                        .index_by(&:assignment_id)
            end
        end

        def standing
          Standing.new(record: record, rule: rule,
                       achievement_values: achievement_values,
                       uses_exam_eligibility: lecture.uses_exam_eligibility?)
        end

        def record
          lecture.student_performance_records.find_by(user_id: user.id)
        end

        # The conditions list walks the required achievements; loading them here
        # keeps that walk from going back to the database.
        def rule
          lecture.active_performance_rule
                 &.tap { |active_rule| active_rule.required_achievements.load }
        end

        # The record says which achievements were met and which are not graded yet,
        # never what was recorded for one ("you have 67.3 %"). Keyed by achievement
        # id, which is what the conditions list holds.
        def achievement_values
          Participation
            .joins(:assessment)
            .where(assessment_assessments: { lecture_id: lecture.id,
                                             assessable_type: "Achievement" },
                   user_id: user.id)
            .where.not(grade_text: [nil, ""])
            .pluck(Assessment.arel_table[:assessable_id], :grade_text)
            .to_h
        end

        # Everything that can still be handed in, soonest deadline first. Each of
        # them needs a card of its own: a sheet weeks away is still a sheet you
        # may hand in early, and a row in the history would take that away.
        def open_sheets
          @open_sheets ||= sheets.select { |sheet| still_open?(sheet) }
                                 .sort_by { |sheet| sheet.assignment.deadline }
        end

        def still_open?(sheet)
          sheet.assignment.active? || sheet.assignment.in_grace_period?
        end

        # The sheet the page leads with, and every sheet sharing its deadline - a
        # lecture may set two for the same date. Deliberately not
        # `Lecture#current_assignments`, which counts only deadlines still ahead:
        # during the grace period the card has the most to say ("15 minutes left")
        # and that method has already dropped the sheet.
        def due
          @due ||= begin
            earliest = open_sheets.first&.assignment&.deadline
            open_sheets.select { |sheet| sheet.assignment.deadline == earliest }
          end
        end

        def latest_marked
          sheets.select { |sheet| sheet.state == :marked }
                .max_by { |sheet| sheet.marked_at || sheet.assignment.deadline }
        end
    end
  end
end
