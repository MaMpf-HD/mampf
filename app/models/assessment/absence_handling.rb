module Assessment
  module AbsenceHandling
    extend self

    class InvalidTransitionError < StandardError; end

    # Every transition reads the row under its lock, so points or a grade
    # being written at the same moment are seen or waited for.
    def mark_absent(participation)
      participation.with_lock do
        validate_not_reviewed!(participation, :absent)

        participation.update!(status: :absent, submitted_at: nil)
      end
    end

    # Applying a scheme gives everyone who did not turn up a 5.0. A certificate
    # handed in afterwards has to take that grade with it, and re-applying the
    # scheme would not: the applier skips exempt participations. Nothing earned
    # is lost, because the way in from `reviewed` is refused below.
    def mark_exempt(participation, note: nil)
      participation.with_lock do
        validate_not_reviewed!(participation, :exempt) unless achievement?(participation)

        attrs = { status: :exempt, submitted_at: nil,
                  grade_numeric: nil, grader: nil, graded_at: nil }
        attrs[:note] = note if note.present?
        participation.update!(attrs)
      end
    end

    # Taking either back returns the row to pending. The 5.0 a scheme gave
    # the no-show goes with the absence, or the row could never be reviewed;
    # an exemption's note goes with the exemption, it explained it.
    def remove_absent(participation)
      participation.with_lock do
        validate_status!(participation, :absent)

        participation.update!(status: :pending, grade_numeric: nil, grader: nil, graded_at: nil)
      end
    end

    def remove_exempt(participation)
      participation.with_lock do
        validate_status!(participation, :exempt)

        participation.update!(status: :pending, note: nil)
      end
    end

    private

      # The messages reach the flash, so they are worded for the reader.
      def validate_status!(participation, status)
        return if participation.status.to_sym == status

        raise(InvalidTransitionError,
              I18n.t("assessment.grading_exam.not_recorded_as", status: status_word(status)))
      end

      def validate_not_reviewed!(participation, target_status)
        return unless participation.reviewed?

        raise(InvalidTransitionError,
              I18n.t("assessment.grading_exam.reviewed_stays",
                     status: status_word(target_status)))
      end

      def status_word(status)
        I18n.t("assessment.grading_exam.status_word.#{status}")
      end

      # An achievement's row carries a value, never marks that an exemption
      # would throw away; a certificate may come after the value.
      def achievement?(participation)
        participation.assessment&.assessable.is_a?(Achievement)
      end
  end
end
