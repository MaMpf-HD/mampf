module Demo
  module EligibilitySetupSupport
    DEMO_RULE_MIN_PERCENTAGE = 50.0
    DEMO_RULE_REQUIRED_ACHIEVEMENT = "Blackboard Talk".freeze

    def setup_eligibility!
      setup_flags!

      lecture = nil
      Demo::QuietLoggingSupport.with_quiet_logging do
        lecture = eligibility_lecture!
      end

      Rails.logger.debug("=== Demo Eligibility Setup ===")
      Demo::QuietLoggingSupport.with_quiet_logging do
        reset_demo_eligibility!(lecture)
        lecture.update!(uses_exam_eligibility: true)
        rule = create_demo_rule!(lecture)
        certify_demo_students!(lecture, rule)
        print_eligibility_summary(lecture)
      end
      Rails.logger.debug("=== Demo Eligibility Setup Complete ===")
    end

    def eligibility_lecture!
      lecture = performance_lecture!
      return lecture if StudentPerformance::Record.exists?(lecture_id: lecture.id)

      # rubocop:disable Rails/Exit
      abort("Lecture #{lecture.id} has no performance records. Run demo:performance first.")
      # rubocop:enable Rails/Exit
    end

    # An achievement a rule requires cannot be deleted (`restrict_with_error`),
    # so the rules have to go before the performance step rebuilds them.
    def reset_eligibility!
      reset_demo_eligibility!(lecture!)
    end

    private

      def reset_demo_eligibility!(lecture)
        StudentPerformance::Certification.where(lecture_id: lecture.id).destroy_all
        StudentPerformance::Rule.where(lecture_id: lecture.id).destroy_all
      end

      def create_demo_rule!(lecture)
        rule = StudentPerformance::Rule.create!(
          lecture: lecture,
          threshold_mode: :percentage,
          min_percentage: DEMO_RULE_MIN_PERCENTAGE,
          active: true
        )

        achievement = demo_achievements(lecture)
                      .find_by(title: DEMO_RULE_REQUIRED_ACHIEVEMENT)
        rule.required_achievements << achievement if achievement

        rule
      end

      # Mirrors what the certifications controller stores for a proposal, so the
      # demo data is indistinguishable from a teacher pressing "accept all".
      # `inconclusive` has no certification status of its own: it waits as
      # `pending`, without a certifier, and its `certified_at` then reads as
      # "last evaluated" rather than "decided".
      def certify_demo_students!(lecture, rule)
        evaluator = StudentPerformance::Evaluator.new(rule)
        records = StudentPerformance::Record.where(lecture_id: lecture.id)
        teacher = lecture.teacher

        evaluator.bulk_evaluate(records).each do |record, result|
          decided = result.proposed_status != :inconclusive

          StudentPerformance::Certification.create!(
            lecture_id: lecture.id,
            user_id: record.user_id,
            status: decided ? result.proposed_status : :pending,
            source: :computed,
            certified_by: decided ? teacher : nil,
            certified_at: Time.current,
            rule: rule
          )
        end
      end

      def print_eligibility_summary(lecture)
        counts = StudentPerformance::Certification
                 .where(lecture_id: lecture.id)
                 .group(:status)
                 .count

        Rails.logger.debug do
          "  certifications: #{counts.map { |s, n| "#{s}=#{n}" }.join(", ")}"
        end
      end
  end
end
