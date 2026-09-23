module StudentPerformance
  # Compute due points on each request because deadlines can pass
  # without a record change that would trigger recomputation.
  class DuePoints
    def initialize(lecture:, kind: nil)
      @lecture = lecture
      @kind = kind
    end

    def total
      @total ||= sum_points(due_assessments)
    end

    def of_kind(kind)
      @of_kind ||= {}
      @of_kind[kind] ||= self.class.new(lecture: @lecture, kind: kind)
    end

    def due?(assessment_id)
      due_assessment_ids.include?(assessment_id)
    end

    # What this student has been weighed against so far: the sheets that are
    # due, minus the ones she was let off, minus the ones still sitting with a
    # tutor, plus the ones she was marked on before their deadline was moved
    # forward. The last of those is the odd one, and it is not hypothetical: a
    # deadline may be extended at any time, and nothing forbids it once marking
    # has begun. `points_total_materialized` counts every reviewed
    # participation whatever the clock says, so a sheet dropped from the base
    # while its points stay in the total turns 20 of 20 into 200 %. What is
    # marked has been weighed, whether or not it can still be handed in.
    #
    # The queue is why the figure differs from student to student otherwise - a
    # sheet nobody has marked yet is neither earned nor lost, and counting it as
    # a zero would put the tutor's backlog on the student's account. A test
    # nobody has entered anything on is in that queue too: whether the student
    # sat it is known only once points or an absence are recorded.
    def marked_max_for(user_id)
      max_for(user_id) - awaiting_marks_points.fetch(user_id, 0) -
        unrecorded_test_points(user_id) + settled_coming_points.fetch(user_id, 0)
    end

    def marked_percentage_for(record)
      marked_percentage_of(record.user_id, record.points_total_materialized || 0)
    end

    # A kind-specific percentage needs that kind's points, not the record's total.
    def marked_percentage_of(user_id, points)
      max = marked_max_for(user_id)
      return nil unless max.positive?

      (points / max * 100).round(2)
    end

    # Use current assignment totals; points_max_materialized may be outdated.
    # An early submission remains not yet due because it can still be replaced
    # or withdrawn until the deadline and submission_grace_period have passed.
    def not_yet_due_for(user_id)
      coming_total -
        exempted_coming_points.fetch(user_id, 0) -
        settled_coming_points.fetch(user_id, 0)
    end

    # The same two sets counted rather than added. A reason on the certification
    # page says how many sheets it is about; the points beside it say what they
    # are worth, and one without the other leaves the reader guessing.
    def not_yet_due_count_for(user_id)
      coming_assessments.size -
        exempted_coming_counts.fetch(user_id, 0) -
        settled_coming_counts.fetch(user_id, 0)
    end

    # Early submissions are not awaiting points: tutors cannot enter points
    # until the deadline and submission_grace_period have passed.
    def pending_points_for(user_id)
      awaiting_marks_points.fetch(user_id, 0) + unrecorded_test_points(user_id)
    end

    def pending_count_for(user_id)
      pending_counts.fetch(user_id, 0) + unrecorded_test_count(user_id)
    end

    private

      def max_for(user_id)
        total - exempted_due_points.fetch(user_id, 0)
      end

      # Handed in, deadline behind it, and still pending: `points_total` counts
      # only what has been reviewed, so these points are in no numerator either.
      # Same shape as the exempt sum above, one grouped query for the page.
      def awaiting_marks_points
        @awaiting_marks_points ||= points_per_user(awaiting_marks, due_assessments)
      end

      def awaiting_marks
        Assessment::Participation
          .where(assessment_id: due_assessments.map(&:id), status: :pending)
          .where.not(submitted_at: nil)
      end

      def assignment_assessments
        scope = Assessment::Assessment
                .where(lecture_id: @lecture.id, assessable_type: "Assignment")
                .joins("JOIN assignments ON assignments.id = " \
                       "assessment_assessments.assessable_id")
                .includes(:tasks).preload(:assessable)
        return scope unless @kind

        scope.where(assignments: { kind: Assignment.kinds.fetch(@kind.to_s) })
      end

      def due_assessments
        @due_assessments ||= assignment_assessments.where(due_condition).to_a
      end

      def coming_assessments
        @coming_assessments ||= assignment_assessments.where.not(due_condition).to_a
      end

      # Tests have no uploads, so their cutoff excludes the submission grace period.
      def due_condition
        ["(assignments.kind = :homework AND assignments.deadline < :graced) OR " \
         "(assignments.kind = :test AND assignments.deadline < :now)",
         { homework: Assignment.kinds.fetch("homework"), test: Assignment.kinds.fetch("test"),
           graced: cutoff, now: Time.zone.now }]
      end

      def coming_total
        @coming_total ||= sum_points(coming_assessments)
      end

      def due_assessment_ids
        @due_assessment_ids ||= due_assessments.to_set(&:id)
      end

      # Include submission_grace_period because a sheet still accepts
      # submissions during that time.
      def cutoff
        @cutoff ||= Time.zone.now -
                    (@lecture.submission_grace_period || 0).minutes
      end

      def sum_points(assessments)
        assessments.sum(&:effective_total_points)
      end

      def exempted_due_points
        @exempted_due_points ||= points_per_user(
          exempt_participations(due_assessments), due_assessments
        )
      end

      def exempted_coming_points
        @exempted_coming_points ||= points_per_user(
          exempt_participations(coming_assessments), coming_assessments
        )
      end

      def exempt_participations(assessments)
        Assessment::Participation
          .where(assessment_id: assessments.map(&:id), status: :exempt)
      end

      def due_tests
        @due_tests ||= due_assessments.select { |assessment| assessment.assessable.kind_test? }
      end

      def unrecorded_test_points(user_id)
        sum_points(due_tests) - recorded_test_points.fetch(user_id, 0)
      end

      def unrecorded_test_count(user_id)
        due_tests.size - recorded_test_counts.fetch(user_id, 0)
      end

      # A test's row with anything on it: points started, reviewed, absent or
      # excused. The rest of the roster, row or no row, is unrecorded.
      def recorded_test_rows
        Assessment::Participation
          .where(assessment_id: due_tests.map(&:id))
          .where("submitted_at IS NOT NULL OR status <> :pending",
                 pending: Assessment::Participation.statuses[:pending])
      end

      def recorded_test_points
        @recorded_test_points ||= points_per_user(recorded_test_rows, due_tests)
      end

      def recorded_test_counts
        @recorded_test_counts ||= count_per_user(recorded_test_rows)
      end

      def exempted_coming_counts
        @exempted_coming_counts ||= count_per_user(
          exempt_participations(coming_assessments)
        )
      end

      # Marked before its deadline was moved forward, or recorded absent from a
      # test in its week: those points are settled - in the total or lost - so
      # they are in the base, and they are not still to be had, which is what
      # `not_yet_due_for` would otherwise say about them.
      def settled_coming
        Assessment::Participation
          .where(assessment_id: coming_assessments.map(&:id), status: [:reviewed, :absent])
      end

      def settled_coming_points
        @settled_coming_points ||= points_per_user(settled_coming, coming_assessments)
      end

      def settled_coming_counts
        @settled_coming_counts ||= count_per_user(settled_coming)
      end

      def pending_counts
        @pending_counts ||= count_per_user(awaiting_marks)
      end

      def count_per_user(scope)
        scope.group(:user_id).count
      end

      def points_per_user(scope, assessments)
        points = assessments.to_h { |a| [a.id, a.effective_total_points] }

        scope.pluck(:user_id, :assessment_id)
             .each_with_object({}) do |(user_id, assessment_id), sums|
               sums[user_id] = (sums[user_id] || 0) +
                               points.fetch(assessment_id, 0)
             end
      end
  end
end
