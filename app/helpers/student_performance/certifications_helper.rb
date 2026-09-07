module StudentPerformance
  module CertificationsHelper
    # Why the rule says what it says today, as the row spells it out. While
    # the assignment list is open every proposal defers for the same reason
    # and the banner above the table gives it once; the rows keep quiet then.
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
