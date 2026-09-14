module Assessment
  module AbsenceHandling
    extend self

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

    # Taking either back returns the row to pending; an exemption's note goes
    # with it, it explained the exemption.
    def remove_absent(participation)
      validate_status!(participation, :absent)

      participation.update!(status: :pending)
    end

    def remove_exempt(participation)
      validate_status!(participation, :exempt)

      participation.update!(status: :pending, note: nil)
    end

    private

      def validate_status!(participation, status)
        return if participation.status.to_sym == status

        raise(InvalidTransitionError,
              "Cannot take back #{status} from a #{participation.status} row")
      end

      def validate_not_reviewed!(participation, target_status)
        return unless participation.reviewed?

        raise(InvalidTransitionError,
              "Cannot transition from reviewed to #{target_status} " \
              "(would discard grading data)")
      end
  end
end
