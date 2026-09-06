module StudentPerformance
  # What a lecture has asked of its students so far, and what is still to come:
  # its assignments split at the deadline, grace period included. Everything
  # here is read-time on purpose — the figures move with the clock, and a
  # materialized calendar value goes stale without anybody noticing.
  #
  # The sheets are the same for the whole lecture, so a screen builds one of
  # these and asks it per student.
  class DuePoints
    def initialize(lecture:)
      @lecture = lecture
    end

    # Before anybody's exemptions: what the lecture asked of everyone.
    def total
      @total ||= sum_points(due_assessments)
    end

    def due?(assessment_id)
      due_assessment_ids.include?(assessment_id)
    end

    # What this student was asked for: the due sheets, less the ones they were
    # excused from.
    def max_for(user_id)
      total - exempted_due_points.fetch(user_id, 0)
    end

    def percentage_for(record)
      max = max_for(record.user_id)
      return nil unless max.positive?

      ((record.points_total_materialized || 0) / max * 100).round(2)
    end

    # The points this student can still be given that no marking backlog knows
    # about: the sheets nobody could hand in yet, less the ones they were
    # excused from and the ones they handed in early. An early hand-in already
    # counts as awaiting marking, and the same sheet must not carry a student
    # twice.
    #
    # Counted from the assignments rather than as the remainder of
    # `points_max_materialized`, which is a snapshot and would turn its own
    # staleness into points that do not exist.
    def not_yet_due_for(user_id)
      coming_total -
        exempted_coming_points.fetch(user_id, 0) -
        submitted_coming_points.fetch(user_id, 0)
    end

    private

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

      # The grace period is part of the deadline: while it runs, the sheet can
      # still be handed in, so it is not due yet.
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

      # The same predicate the computation service counts as awaiting marking,
      # so that what is subtracted here is exactly what it added there.
      def submitted_coming_points
        @submitted_coming_points ||= points_per_user(
          Assessment::Participation
            .where(assessment_id: coming_assessments.map(&:id),
                   status: :pending)
            .where.not(submitted_at: nil),
          coming_assessments
        )
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
