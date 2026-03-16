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

    def mark_exempt(participation, note: nil)
      validate_not_reviewed!(participation, :exempt)

      attrs = { status: :exempt, submitted_at: nil }
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
