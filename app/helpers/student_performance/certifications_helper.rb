module StudentPerformance
  module CertificationsHelper
    # The reasons a row spells out. While `assignments_complete?` is false
    # every proposal defers for the same reason, and the box above the table
    # gives it once, so the rows stay empty.
    # The row's buttons look like the marking tables' rows' do.
    def row_action_classes
      ParticipationRowComponent::ROW_ACTION_CLASSES
    end

    def proposal_reasons(proposal, lecture)
      case proposal.proposed_status
      when :failed
        proposal.missed_criteria.map do |criterion|
          t("student_performance.evaluator.missed.#{criterion}")
        end
      when :inconclusive
        return [] unless lecture.assignments_complete?

        proposal.verdict_deferral_reasons.map do |reason|
          deferral_text(proposal, reason)
        end
      else
        []
      end
    end

    # Two of the reasons can say how many sheets they are about, and a reader
    # deciding on somebody needs that: "not due yet" covers anything between
    # one sheet and the rest of the term.
    def deferral_text(proposal, reason)
      case reason
      when :points_not_due
        not_due_text(proposal.details[:not_due_sheets], proposal.details[:not_due_tests])
      when :points_pending
        deferral_count(reason, proposal.details[:pending_sheets])
      else
        t("student_performance.evaluator.deferral.#{reason}")
      end
    end

    # Dropping a pass is the one reset with a consequence outside this page.
    def reset_confirmation(certification)
      text = t("student_performance.certifications.index.reset_confirm")
      return text unless certification.passed?

      "#{text} #{t("student_performance.certifications.index.reset_confirm_passed")}"
    end

    private

      def deferral_count(reason, sheets)
        t("student_performance.evaluator.deferral.#{reason}", count: sheets.to_i)
      end

      def not_due_text(sheets, tests)
        parts = []
        if sheets.to_i.positive?
          parts << t("student_performance.evaluator.deferral.sheet_count", count: sheets)
        end
        if tests.to_i.positive?
          parts << t("student_performance.evaluator.deferral.test_count", count: tests)
        end
        t("student_performance.evaluator.deferral.points_not_due", what: parts.to_sentence)
      end
  end
end
