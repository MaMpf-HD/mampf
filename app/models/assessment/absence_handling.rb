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

    # TODO: think abt better submitted_at handling
    # submitted at must be set to non nil so that the grading can recognize the record
    # but its prior value is lost.
    # but we need to provide a means for user to remove absent status 
    def remove_absent(participation)
      validate_absent!(participation)

      participation.update!(
        status: :pending,
        submitted_at: Time.current
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

    # TODO: think abt better submitted_at handling
    def remove_exempt(participation)
      validate_exempt!(participation)

      participation.update!(
        status: :pending,
        submitted_at: Time.current,
        note: nil
      )
    end

    private

      def validate_not_reviewed!(participation, target_status)
        return unless participation.reviewed?

        raise(InvalidTransitionError,
              "Cannot transition from reviewed to #{target_status} " \
              "(would discard grading data)")
      end

      def validate_absent!(participation)
        return if participation.absent?

        raise(InvalidTransitionError,
              "Cannot remove absent status from a participation that is not absent")
      end

      def validate_exempt!(participation)
        return if participation.exempt?

        raise(InvalidTransitionError,
              "Cannot remove exempt status from a participation that is not exempt")
      end
  end
end
