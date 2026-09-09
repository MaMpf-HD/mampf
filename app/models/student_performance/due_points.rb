module StudentPerformance
  # Compute due points on each request because deadlines can pass
  # without a record change that would trigger recomputation.
  class DuePoints
    def initialize(lecture:)
      @lecture = lecture
    end

    def total
      @total ||= sum_points(due_assessments)
    end

    def due?(assessment_id)
      due_assessment_ids.include?(assessment_id)
    end

    # What this student has been weighed against so far: the sheets that are
    # due, minus the ones she was let off, minus the ones still sitting with a
    # tutor. The last of those is why the figure differs from student to
    # student - a sheet nobody has marked yet is neither earned nor lost, and
    # counting it as a zero would put the tutor's backlog on the student's
    # account.
    def marked_max_for(user_id)
      max_for(user_id) - awaiting_marks_points.fetch(user_id, 0)
    end

    def marked_percentage_for(record)
      max = marked_max_for(record.user_id)
      return nil unless max.positive?

      ((record.points_total_materialized || 0) / max * 100).round(2)
    end

    # Sum points from the current assignments: subtracting due points
    # from points_max_materialized could count outdated totals as
    # points that are not yet due.
    def not_yet_due_for(user_id)
      coming_total -
        exempted_coming_points.fetch(user_id, 0) -
        submitted_coming_points.fetch(user_id, 0)
    end

    # The same two sets counted rather than added. A reason on the certification
    # page says how many sheets it is about; the points beside it say what they
    # are worth, and one without the other leaves the reader guessing.
    def not_yet_due_count_for(user_id)
      coming_assessments.size -
        exempted_coming_counts.fetch(user_id, 0) -
        submitted_coming_counts.fetch(user_id, 0)
    end

    # Deliberately every sheet, not only the due ones: the reason it belongs to
    # says that something is sitting with a tutor, and for that the deadline is
    # beside the point. It counts what `points_max_pending_materialized` sums,
    # so the two are the same set.
    def pending_count_for(user_id)
      pending_counts.fetch(user_id, 0)
    end

    private

      def max_for(user_id)
        total - exempted_due_points.fetch(user_id, 0)
      end

      # Handed in, deadline behind it, and still pending: `points_total` counts
      # only what has been reviewed, so these points are in no numerator either.
      # Same shape as the exempt sum above, one grouped query for the page.
      def awaiting_marks_points
        @awaiting_marks_points ||= points_per_user(
          Assessment::Participation
            .where(assessment_id: due_assessments.map(&:id), status: :pending)
            .where.not(submitted_at: nil),
          due_assessments
        )
      end

      def assignment_assessments
        Assessment::Assessment
          .where(lecture_id: @lecture.id, assessable_type: "Assignment")
          .joins("JOIN assignments ON assignments.id = " \
                 "assessment_assessments.assessable_id")
          .includes(:tasks)
      end

      def due_assessments
        @due_assessments ||= assignment_assessments
                             .where(assignments: { deadline: ...cutoff }).to_a
      end

      def coming_assessments
        @coming_assessments ||= assignment_assessments
                                .where(assignments: { deadline: cutoff.. }).to_a
      end

      def coming_total
        @coming_total ||= sum_points(coming_assessments)
      end

      def due_assessment_ids
        @due_assessment_ids ||= due_assessments.to_set(&:id)
      end

      # Include submission_grace_period because an Assignment still
      # accepts submissions during that time.
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

      # Match ComputationService#pending_points so pending submissions are
      # not counted again as points not yet due.
      def submitted_coming_points
        @submitted_coming_points ||= points_per_user(submitted_coming, coming_assessments)
      end

      def submitted_coming
        Assessment::Participation
          .where(assessment_id: coming_assessments.map(&:id), status: :pending)
          .where.not(submitted_at: nil)
      end

      def exempted_coming_counts
        @exempted_coming_counts ||= count_per_user(
          exempt_participations(coming_assessments)
        )
      end

      def submitted_coming_counts
        @submitted_coming_counts ||= count_per_user(submitted_coming)
      end

      def pending_counts
        @pending_counts ||= count_per_user(
          Assessment::Participation
            .where(assessment_id: assignment_assessments.select(:id),
                   status: :pending)
            .where.not(submitted_at: nil)
        )
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
