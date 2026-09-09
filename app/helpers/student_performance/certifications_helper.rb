module StudentPerformance
  module CertificationsHelper
    # The reasons a row spells out. While `assignments_complete?` is false
    # every proposal defers for the same reason, and the box above the table
    # gives it once, so the rows stay empty.
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
        deferral_count(reason, proposal.details[:not_due_sheets])
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
  end
end
