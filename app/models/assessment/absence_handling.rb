module Assessment
  module AbsenceHandling
    class InvalidTransitionError < StandardError; end

    def mark_absent(participation)
      validate_not_reviewed!(participation, :absent)

      participation.update!(
        status: :absent,
        submitted_at: nil
      )
    end

    # Applying a scheme gives everyone who did not turn up a 5.0. A certificate
    # handed in afterwards has to take that grade with it, and re-applying the
    # scheme would not: the applier skips exempt participations. Nothing earned
    # is lost, because the way in from `reviewed` is refused below.
    def mark_exempt(participation, note: nil)
      validate_not_reviewed!(participation, :exempt)

      attrs = { status: :exempt, submitted_at: nil,
                grade_numeric: nil, grader: nil, graded_at: nil }
      attrs[:note] = note if note.present?
      participation.update!(attrs)
    end

    private

      def validate_not_reviewed!(participation, target_status)
        return unless participation.reviewed?

        raise(InvalidTransitionError,
              "Cannot transition from reviewed to #{target_status} " \
              "(would discard grading data)")
      end
  end
end
