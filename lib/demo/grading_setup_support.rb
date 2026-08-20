module Demo
  module GradingSetupSupport
    include Assessment::AbsenceHandling

    DEMO_EXAM_TASKS = [
      { description: "Problem 1", max_points: 10, position: 1 },
      { description: "Problem 2", max_points: 15, position: 2 },
      { description: "Problem 3", max_points: 20, position: 3 },
      { description: "Problem 4", max_points: 10, position: 4 },
      { description: "Problem 5", max_points: 5, position: 5 }
    ].freeze

    DEMO_TOTAL_POINTS = DEMO_EXAM_TASKS.sum { |task| task[:max_points] }
    DEMO_SCHEME_PASSING = 27
    DEMO_SCHEME_EXCELLENCE = 54
    DEMO_ABSENT_COUNT = 3
    DEMO_EXEMPT_COUNT = 1

    def setup_grading!

      exam = nil
      Demo::QuietLoggingSupport.with_quiet_logging do
        exam = grading_exam!
      end

      summary = []
      Rails.logger.debug("=== Demo Grading Setup ===")
      Demo::QuietLoggingSupport.with_quiet_logging do
        reset_demo_grading!(exam)
        create_demo_exam_tasks!(exam)
        create_demo_participations!(exam)
        record_demo_absences!(exam)
        seed_demo_exam_points!(exam)
        apply_demo_grade_scheme!(exam)
        summary = grading_summary(exam)
      end

      # Quieting the SQL quiets this too — ActiveRecord and Rails share the one
      # logger — so the summary waits until the log is loud again.
      summary.each { |line| Rails.logger.debug(line) }
      Rails.logger.debug("=== Demo Grading Setup Complete ===")
    end

    def grading_exam!
      lecture = exam_lecture!
      exam = Exam.find_by(lecture_id: lecture.id,
                          title: Demo::ExamSetupSupport::DEMO_MIDTERM_TITLE)
      return exam if exam&.exam_roster_entries&.exists?

      # rubocop:disable Rails/Exit
      abort("No finalized demo exam roster. Run demo:exams first.")
      # rubocop:enable Rails/Exit
    end

    private

      # An applied scheme refuses every change, and a task with points entered
      # refuses to be destroyed. Demo data is not worth working around either
      # one call at a time, so it goes by the shortest route.
      def reset_demo_grading!(exam)
        assessment = exam.assessment
        return unless assessment

        participation_ids = assessment.assessment_participations.select(:id)
        Assessment::TaskPoint.where(assessment_participation_id: participation_ids)
                             .delete_all
        Assessment::GradeScheme.where(assessment_id: assessment.id).delete_all
        assessment.assessment_participations.delete_all
        assessment.tasks.delete_all
      end

      # Before the participations: a new task reopens everyone already reviewed,
      # so building the paper first saves undoing that.
      def create_demo_exam_tasks!(exam)
        DEMO_EXAM_TASKS.each { |attrs| exam.assessment.tasks.create!(attrs) }
      end

      def create_demo_participations!(exam)
        tutorial_ids = TutorialMembership.where(tutorial_id: exam.lecture.tutorial_ids)
                                         .pluck(:user_id, :tutorial_id)
                                         .to_h

        exam.exam_roster_entries.where(excluded_at: nil).find_each do |entry|
          exam.assessment.assessment_participations.create!(
            user_id: entry.user_id,
            tutorial_id: tutorial_ids[entry.user_id],
            status: :pending,
            submitted_at: exam.date
          )
        end
      end

      # Both absence states, because the scheme treats them differently: the
      # no-shows are graded 5.0 when it is applied, the excused one is skipped
      # and stays without a grade.
      def record_demo_absences!(exam)
        pool = exam.assessment.assessment_participations
                   .order(:id)
                   .limit(DEMO_ABSENT_COUNT + DEMO_EXEMPT_COUNT)
                   .to_a

        pool.first(DEMO_ABSENT_COUNT).each { |participation| mark_absent(participation) }
        pool.last(DEMO_EXEMPT_COUNT).each do |participation|
          mark_exempt(participation, note: "Medical certificate on file.")
        end
      end

      def seed_demo_exam_points!(exam)
        assessment = exam.assessment
        tasks = assessment.tasks.order(:position).to_a
        teacher = exam.lecture.teacher

        assessment.assessment_participations
                  .where(status: :pending)
                  .find_each do |participation|
          seed_exam_points_for!(participation, tasks, teacher)
          participation.update!(status: :reviewed)
        end
      end

      # Seeded from the user id rather than left to chance, so a student's marks
      # come out the same on every run instead of being redrawn.
      def seed_exam_points_for!(participation, tasks, teacher)
        rng = Random.new(participation.user_id)
        quality = rng.rand(0.25..0.98)

        tasks.each do |task|
          Assessment::TaskPoint.create!(
            assessment_participation: participation,
            task: task,
            points: demo_exam_points_for(task, quality + rng.rand(-0.08..0.08)),
            grader: teacher
          )
        end
      end

      def demo_exam_points_for(task, quality)
        half_steps = (quality * task.max_points * 2).round
        half_steps.clamp(0, task.max_points * 2) / 2.0
      end

      # The point of the slice: grades come out of the bands, so the demo lets
      # the applier write them instead of handing out numbers itself.
      def apply_demo_grade_scheme!(exam)
        scheme = Assessment::GradeScheme.create!(
          assessment: exam.assessment,
          kind: :banded,
          active: true,
          points_step: 1,
          config: Assessment::GradeScheme.two_point_auto(
            excellence: DEMO_SCHEME_EXCELLENCE,
            passing: DEMO_SCHEME_PASSING,
            max_points: DEMO_TOTAL_POINTS
          )
        )

        Assessment::GradeSchemeApplier.new(scheme)
                                      .apply!(applied_by: exam.lecture.teacher)
      end

      def grading_summary(exam)
        participations = exam.assessment.assessment_participations
        statuses = participations.group(:status).count
        grades = participations.where.not(grade_numeric: nil)
                               .group(:grade_numeric)
                               .count
                               .sort

        ["  #{exam.title}: #{statuses.map { |s, n| "#{s}=#{n}" }.join(", ")}",
         "  grades: #{grades.map { |grade, n| "#{grade.to_f}=#{n}" }.join(", ")}"]
      end
  end
end
