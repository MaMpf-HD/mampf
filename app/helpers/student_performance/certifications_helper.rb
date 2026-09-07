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
          t("student_performance.evaluator.deferral.#{reason}")
        end
      else
        []
      end
    end

    # Dropping a pass is the one reset with a consequence outside this page.
    def reset_confirmation(certification)
      text = t("student_performance.certifications.index.reset_confirm")
      return text unless certification.passed?

      "#{text} #{t("student_performance.certifications.index.reset_confirm_passed")}"
    end
  end
end
